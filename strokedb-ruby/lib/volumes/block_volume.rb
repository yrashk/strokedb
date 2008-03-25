require 'readbytes'
module StrokeDB
  
  # TODO: inherit from the common AbstractVolume
  class BlockVolume
    attr_reader :file_path, :blocks_count
    
    HEADER_LENGTH = 8 # block_size, blocks_count
    DEFAULT_BLOCKS_COUNT = 1024
    DEFAULT_PATH = "."
        
    # Open a volume in a directory +:path+, with UUID +:uuid+
    # and a specified +:block_size+. If the file does not exist, it is created 
    # and filled with zero bytes up to the specified size. 
    # Otherwise, it is just opened and ready for reads and writes.
    # File contains +block_count+ blocks of :block_size: bytes size.
    # When insertion is done to a new position, file is autoextended.
    #
    # Required params: +:block_size+ and +:uuid+
    # Default +:path+ is ".", +:blocks_count+ is 1024
    #
    # Example:
    #   DataVolume.new(:uuid => uuid, :path => "/var/dir", :block_size => 1024)
    #
    def initialize(options = {})
      @options = options.stringify_keys.reverse_merge(
        'path' => DEFAULT_PATH, 
        'blocks_count' => DEFAULT_BLOCKS_COUNT)
      initialize_file
    end
    
    # Read a record sitting in a +position+ in the volume file.
    # Record length is stored in a first 4 bytes before the record.
    # 
    def read(index)
      csize = @block_size
      @file.seek(HEADER_LENGTH + index * csize)
      @file.readbytes(csize)
    end
    
    # Write some data to the end of the file.
    # Returns record position.
    #
    def insert(index, data)
      extend_volume! if index >= @blocks_count
      csize = @block_size
      @file.seek(HEADER_LENGTH + index * csize)
      @file.write(data)
      self
    end
    
    # Close the volume file. You cannot read/insert after that operation.
    # In such case, VolumeClosedException is raised. 
    # Call DataVolume.new to open volume again.
    #
    def close!
      safe_close
    end
    
    # Close and delete the volume file. You cannot read/insert after that 
    # operation. In such case, VolumeClosedException is raised.
    #
    def delete!
      safe_close
      File.delete(@file_path)
    end

    def path
      @options['path']
    end
    
    def block_size
      @options['block_size']
    end
    
    def blocks_count
      @options['blocks_count']
    end
    
    def uuid
      case @options['uuid'] 
      when /^#{UUID_RE}$/
        @options['uuid']
      when nil
        @options['uuid'] = Util.random_uuid
      else
        @options['uuid'] = @options['uuid'].to_formatted_uuid
      end
    end
    
    # VolumeClosedException is thrown when you call +read+ or +insert+
    # method on a closed or deleted volume.
    #
    class VolumeClosedException < Exception; end
      
  private

    def initialize_file
      @file_path = File.join(path, hierarchify(uuid) + ".blocks")
      create_file(@file_path, block_size, blocks_count) unless File.exist?(@file_path)
      @file = File.open(@file_path, File::RDWR)
      @block_size, @blocks_count = read_header(@file)
      if @block_size != block_size && block_size != nil
        raise "Block size collision! Declared #{block_size} bytes, but actually file is formatted by #{@block_size}-byte blocks."
      end
    end
    
    # Extends volume to a double size.
    #
    def extend_volume!
      @file.close
      @blocks_count *= 2
      create_file(@file_path, @block_size, @blocks_count)
      @file = File.open(@file_path, File::RDWR)
    end
    
    # Create file skeleton filled with zeros with a prefix 
    # containing current file tail.
    #
    def create_file(path, block_size, blocks)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, File::CREAT | File::WRONLY) do |f|
        f.truncate(HEADER_LENGTH + block_size*blocks)
        write_header(f, block_size, blocks)
      end
    end
    
    # Close the file if it is opened and remove
    # +read+ and +write+ methods from the instance.
    #
    def safe_close
      @file.close if @file
      @file = nil
      class <<self
        alias :read  :raise_volume_closed
        alias :insert :raise_volume_closed
      end
    end
    
    # +read+ and +insert+ methods are aliased to this
    # when file is closed or deleted.
    #
    def raise_volume_closed(*args)
      raise VolumeClosedException, "Throw this object away and instantiate another one."
    end
    public :raise_volume_closed
    
    # Transform filename "aabbccdd" into "aa/bb/aabbccdd"
    # for faster access to a bunch of datavolumes.
    #
    def hierarchify(filename)
      File.join(filename[0,2], filename[2,2], filename)
    end
    
    # Read current file block size and blocks count.
    # 
    def read_header(f)
      f.seek(0)
      f.readbytes(8).unpack('N2')
    end
    
    # Update file's end position.
    #
    def write_header(f, block_size, blocks)
      f.seek(0)
      f.write([block_size, blocks].pack('N2'))
    end
  end
end
