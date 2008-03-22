require 'readbytes'
module StrokeDB
  class DataVolume
    attr_accessor :file_path, :uuid, :size, :tail
    
    def initialize(dir_path, raw_uuid, size)
      @uuid = raw_uuid
      @size = size
      @file_path = dir_path + "/" + hierarchify(raw_uuid.to_formatted_uuid) + ".dv"
      create_file(@file_path, size) unless File.exist?(@file_path)
      @file = File.open(@file_path, File::RDWR)
      @tail = read_tail(@file)
    end
    
    def read(position)
      @file.seek(position)
      size = @file.readbytes(4).unpack('N').first
      @file.readbytes(size)
    end
    
    def write(data)
      @file.seek(@tail)
      @file.write([data.size].pack('N') + data)
      t = @tail
      @tail += 4 + data.size 
      write_tail(@file, @tail)
      t
    end
    
    def close!
      safe_close
    end
    
    def delete!
      safe_close
      File.delete(@file_path)
    end
    
    class VolumeClosedException < Exception; end

  private
  
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
    
    def safe_close
      @file.close if @file
      @file = nil
      instance_eval do 
        def read(*args)
          raise VolumeClosedException, "Throw this object away and instantiate another one."
        end
        def write(*args)
          raise VolumeClosedException, "Throw this object away and instantiate another one."
        end
      end
    end
    
    def hierarchify(filename)
      filename[0,2] + "/" +
      filename[2,2] + "/" +
      filename
    end
    
    def read_tail(f)
      f.seek(0)
      f.readbytes(4).unpack('N').first
    end
    
    def write_tail(f, pos)
      f.seek(0)
      f.write([pos].pack('N'))
      pos
    end
    
  end
end
