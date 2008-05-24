require 'digest/md5' # for log message signature
require 'fileutils'
module StrokeDB
  # Skiplist by its nature must be loaded into memory and dumped on a disk 
  # as a whole thing. Since it is a pretty slow operation, we use a WAL
  # (write ahead log) to keep skiplist in memory most of the time and put
  # all updates in the log. 
  # * When skiplist is dumped to the disk, new log is created. 
  # * When volume is opened, it loads a skiplist into the memory
  #   and applies the log to it.
  # * When log becomes too large, or #dump! is called explicitely 
  #   skiplist is safely dumped to the disk.
  #
  # SAFETY 
  # 
  # 0) write something to the in-memory skiplist and a log
  #   (don't response while log is not updated)
  # 1) dump the skiplist to a temporary file
  # 2) atomically rename the tmpfile to the destination file
  # 3) atomically rename current log to some archive name
  # 4) remove archive log
  # 0) write something to the in-memory skiplist and a log
  #
  # Crash may happen after the steps 0, 1, 2, 3, 4.
  # Let's analyze all the possible situations:
  # 0) Data is lost from the memory, but is stored in a log.
  #    On restart we just load an already dumped skiplist 
  #    and replay the log.
  # 1) Same as above, but we have a temporary dump file 
  #    (possibly, partially written) on a disk.
  #    On restart we just remove this file.
  # 2) Skiplist is successfully dumped, but the log contains
  #    operations to be applied on restart.
  #    It is not a problem, since log's data is just the same,
  #    as already stored, so we just replay it.
  # 3) Skiplist is dumped, log is renamed, but is stored on a disk.
  #    On restart we load the skiplist, remove stale logfile and open a new one.
  # 4) No stale files on the disk, log is empty, so the crash case is 
  #    just a regular "close" case. 
  # 
  # According to this, all we have to do is to:
  # 1) Do the durable updates to the log before in-memory operations.
  # 2) Remove all the stale files on restart.
  # 3) Load the skiplist from the regular file.
  # 4) Replay the actual log on restart.
  # 
  class SkiplistVolume
    
    # Data is dumped to the disk every time log exceeds this limit
    # Set "max_log_size" option when initializing the volume to override this.
    DEFAULT_MAX_LOG_SIZE = 16*1024*1024
    
    # Encoded log message consists of the key, value, length prefixes and
    # MD5 checksum. Skiplist is not intended for storing huge key or values:
    # several kilobytes is okay. 
    # This limit helps to fight incorrect log messages while replaying the log.
    MAX_LOG_MSG_LENGTH = 1024*1024
    
    def initialize(params)
      @params = params.stringify_keys
      @path = @params['path']
      @silent = @params['silent']
      if @silent
        class << self
          def info(*args); end
          def error(*args); end
        end
      end
      @max_log_size = (@params['max_log_size'] || DEFAULT_MAX_LOG_SIZE).to_i
      
      FileUtils.mkdir_p(File.dirname(@path))
      
      @list_path    = @path               # regular file for a skiplist
      @list_tmppath = @path + ".tmp"      # tempfile skiplist is dumped to
      @log_path     = @path + ".wal"      # write ahead log
      @log_tmppath  = @path + ".wal.tmp"  # tempfile for the WAL
      
      if File.exists?(@list_tmppath)
        info "Unfinished dump file detected (#{@list_tmppath}). Removing the file." 
        File.delete(@list_tmppath)
      end
      if File.exists?(@log_tmppath)
        info "Unfinished WAL removal detected (#{@log_tmppath}). Removing the file."
        File.delete(@log_tmppath)
      end
      
      if File.exists?(@list_path)
        @list = SimpleSkiplist.load(File.read(@list_path))
      else
        info "List file (#{@list_path}) was not found, creating a brand new skiplist."
        @list = SimpleSkiplist.new(@params)
      end
      
      if File.exists?(@log_path)
        info "Log file detected (#{@log_path}), applying it to the loaded skiplist."
        replay_log!(@log_path, @list)
      end
      
      @log_file = init_log_file(@log_path)
      
    rescue => e
      crash!(e)
      raise
    end
    
    # Skiplist operations
    def empty?
      @list.empty?
    end
    
    def search(*args)
      @list.search(*args)
    end
    
    def each(*args, &block)
      @list.each(*args, &block)
    end
    
    def find(key)
      @list.find(key)
    end
    
    def insert(key, value, __level = nil)
      write_log(key, value, __level)
      @list.insert(key, value, __level)
      dump! if @log_bytes > @max_log_size
      self
    rescue => e
      crash!(e)
      raise
    end

    def delete(key)
      write_log(key, 0, 0)
      @list.delete(key)
      dump! if @log_bytes > @max_log_size
      self
    rescue => e
      crash!(e)
      raise
    end
    
    # Volume operations
    
    # Dumps the skiplist and closes log for writing.
    # Read-only access remains.
    def close!
      dump!
      @log_file.close
      File.delete(@log_file.path)
      self
      class <<self
        alias :insert :raise_volume_closed
        alias :close! :raise_volume_closed
        alias :dump!  :raise_volume_closed
        def closed?; true; end
      end
    end
    
    def closed?
      false
    end
    
    def dump!
      dumped_list = @list.dump
      f = File.open(@list_tmppath, 'w')
      f.sync = true
      f.write(dumped_list)
      f.fsync
      f.close
      
      File.rename(@list_tmppath, @list_path)
      File.rename(@log_path, @log_tmppath)
      File.delete(@log_tmppath)
      
      @log_file = init_log_file(@log_path)
      self
    rescue => e
      error "Dump failed!"
      crash!(e)
      raise
    end
    
    # This makes volume instance unusable
    def crash!(err = nil)
      if err.is_a? Exception
        backtrace = err.backtrace.join("\n")
        error "Crashed with #{err}: #{err.message}\n#{backtrace}"
      else
        error "Crashed with #{exception.inspect}!"
      end
      class <<self
        alias :insert :raise_volume_crashed
        alias :close! :raise_volume_crashed
        alias :dump!  :raise_volume_crashed
      end
    end
    
    class LogFormatError < StandardError; end
    class VolumeClosedException < StandardError; end
    class VolumeCrashedException < StandardError; end
    class MessageTooBig < StandardError; end
    
  private
    
    N_F = "N".freeze
    CHECKSUM_LENGTH = 16 # MD5
    
    def replay_log!(log_path, list)
      nf = N_F
      max_msg_length = MAX_LOG_MSG_LENGTH
      checksum_length = CHECKSUM_LENGTH
      
      @log_bytes = 0
      
      File.open(@log_path, "r") do |f|
        until f.eof?
          msg_length   = f.read(4).unpack(nf).first rescue nil
          (!msg_length || msg_length > max_msg_length) and raise LogFormatError, "Wrong WAL message length prefix!"
        
          msg_chk = f.read(msg_length + checksum_length)
          msg = msg_chk[0, msg_length]
        
          @log_bytes += 4 + msg_length + checksum_length
        
          checksum_invalid(msg, msg_chk[msg_length, checksum_length]) and raise LogFormatError, "WAL message checksum failure!"
        
          key, value, level = Marshal.load(msg)
          
          if level == 0
            list.delete(key)
          else
            list.insert(key, value, level)
          end
        end
      end
    
    # Log is malformed. This can happen in two situations:
    # 1) latest insert operation was not committed
    #    (so we can just remove a log)
    # 2) log was broken afterwards 
    #    (we should try a backup log, notify someone...) 
    # 
    # For now, we trust underlying filesystem and handle case #1 only.
    #
    rescue LogFormatError => e
      error e.message + " Dumping the skiplist and recreating a log."
      dump!
      
    # Some strange error occured
    rescue => e
      crash! e
      raise
    end
    
    def write_log(key, value, level)
      msg = Marshal.dump([key, value, level])
      if msg.size > MAX_LOG_MSG_LENGTH
        raise MessageTooBig, "Key-value pair is too big to be inserted (limit is #{MAX_LOG_MSG_LENGTH} bytes)"
      end
      digest = Digest::MD5.digest(msg)
      @log_file.write([msg.size].pack(N_F))
      @log_file.write(msg)
      @log_file.write(digest)
      # fsync is needed to flush OS buffers to the disk. 
      # It makes writes 10 times (!) slower but reliable.
      @log_file.fsync 
      @log_bytes += 4 + msg.size + CHECKSUM_LENGTH
    end
    
    def checksum_invalid(msg, chk)
      chk != Digest::MD5.digest(msg) rescue true
    end
  
    # +insert+ method is aliased with this on close.
    def raise_volume_closed(*args)
      raise VolumeClosedException, "Throw this object away and instantiate another one."
    end
    public :raise_volume_closed

    # +insert+ method is aliased with this on crash.
    def raise_volume_crashed(*args)
      raise VolumeCrashedException, "Throw this object away and instantiate another one."
    end
    public :raise_volume_crashed
    
    def init_log_file(path)
      @log_bytes = 0
      log_file = File.open(path, "a")
      log_file.sync = true
      log_file
    end
    
    def info(m)
      DEBUG { STDOUT.puts "SkiplistVolume#info: #{m}" }
    end
    
    def error(m)
      STDERR.puts "SkiplistVolume#error: #{m}"
    end
  
  end
end
