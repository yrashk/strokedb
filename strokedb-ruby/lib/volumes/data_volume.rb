require 'readbytes'
module StrokeDB
  class DataVolume
    attr_accessor :file_path, :uuid, :size, :tail
    
    DEFAULT_SIZE = 64*1024*1024
    DEFAULT_PATH = "."
    
    # Open a volume in a directory +:path+, with UUID (raw value)
    # and a specified +:size+. If the file does not exist, it is created 
    # and filled with zero bytes up to the specified size. 
    # Otherwise, it is just opened and ready for reads and writes.
    #
    # Defaults:
    #   :path => "."
    #   :size => 64 Mb
    #
    # Example:
    #   DataVolume.new(uuid, :path => "/var/dir", :size => 1024)
    #
    def initialize(options = {})
      @options = options.stringify_keys
      @uuid = @options['raw_uuid']
      @size    = @options['size'] || DEFAULT_SIZE
      dir_path = @options['path'] || DEFAULT_PATH
      
      @file_path = File.join(dir_path, hierarchify(@uuid.to_formatted_uuid) + ".dv")
      create_file(@file_path, @size) unless File.exist?(@file_path)
      @file = File.open(@file_path, File::RDWR)
      @tail = read_tail(@file)
    end
    
    # Read a record sitting in a +position+ in the volume file.
    # Record length is stored in a first 4 bytes before the record.
    # 
    def read(position)
      @file.seek(position)
      size = @file.readbytes(4).unpack('N').first
      @file.readbytes(size)
    end
    
    # Write some data to the end of the file.
    # Returns record position.
    #
    def insert(data)
      @file.seek(@tail)
      @file.write([data.size].pack('N') + data)
      t = @tail
      @tail += 4 + data.size 
      write_tail(@file, @tail)
      t
    end
    
    # Close the volume file. You cannot read/write after that operation.
    # In such case, VolumeClosedException is raised. 
    # Call DataVolume.new to open volume again.
    #
    def close!
      safe_close
    end
    
    # Close and delete the volume file. You cannot read/write after that 
    # operation. In such case, VolumeClosedException is raised.
    #
    def delete!
      safe_close
      File.delete(@file_path)
    end
    
    # VolumeClosedException is thrown when you call +read+ or +write+
    # method on a closed or deleted volume.
    #
    class VolumeClosedException < Exception; end

  private
    
    # Create file skeleton filled with zeros with a prefix 
    # containing current file tail.
    #
    def create_file(path, size)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, File::CREAT | File::EXCL | File::WRONLY) do |f|
        zeros = "\x00"*1024
        (size/1024).times do 
          f.write(zeros)
        end
      end
      File.open(path, File::WRONLY) do |f|
        write_tail(f, 4) # 4 is a size of long type.
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
    
    # +read+ and +write+ methods are aliased to this
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
    
    # Read current file end position ("tail") from the file header.
    # 
    def read_tail(f)
      f.seek(0)
      f.readbytes(4).unpack('N').first
    end
    
    # Update file's end position.
    #
    def write_tail(f, pos)
      f.seek(0)
      f.write([pos].pack('N'))
      pos
    end
  end
end
