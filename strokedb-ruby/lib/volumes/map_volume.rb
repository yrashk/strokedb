require 'readbytes'
module StrokeDB

  class InvalidRecordSizeError < Exception
  end

  class InvalidRecordPositionError < Exception
  end

  class MapVolumeCapacityExceeded < Exception
  end

  class InvalidMapVolumeError < Exception
  end

  class MapVolume

    HEADER_SIZE = 512
    MAGIC_SIGNATURE = "\x11\x12\x19\x81"
    VERSION = "00"

    attr_accessor :first_available_position

    def initialize(options = {})
      @options = options.stringify_keys
      initialize_file
    end

    def insert!(record)
      position = find_first_available_position
      write!(position,record)
    end

    def write!(position,record)
      raise InvalidRecordSizeError if record.size != record_size
      decrement_available_capacity!(position)
      write_at_position!(position,record)
      position
    end

    def read(position)
      raise InvalidRecordPositionError if available?(position)
      read_at_position(position)
    end

    def delete!(position)
      self.first_available_position = -1
      increment_available_capacity!(position)
    end

    def available?(position)
      read_map_byte(position) & (1 << (position % 8)) == 0
    end

    def empty?
      read_map == "\x00" * map_size
    end

    def record_size
      @options['record_size']
    end

    def path
      @options['path']
    end

    def close!
      @bitmap_file.close
    end

    private

    def initialize_file
      FileUtils.mkdir_p path
      bitmap_path = File.join(path,'bitmap')
      data_path = File.join(path,'data')
      unless File.exists?(bitmap_path)
        @bitmap_file = File.new(bitmap_path,'w+')
        @first_available_position = 0
        initialize_file_header!
        initialize_file_map!
      else
        @bitmap_file = File.new(bitmap_path,'r+')
        @first_available_position = -1
        read_file_header
        initialize_file_header!
      end
      unless File.exists?(data_path)
        @data_file = File.new(data_path,'w+')
      else
        @data_file = File.new(data_path,'r+')
      end
    end

    def read_file_header
      @bitmap_file.seek(0)
      begin
        header = @bitmap_file.readbytes(HEADER_SIZE)
      rescue TruncatedDataError
        raise InvalidMapVolumeError
      end
      raise InvalidMapVolumeError unless header[0,4] = MAGIC_SIGNATURE
      @options['record_size'] = header[6,4].unpack("N").first
      @first_available_position = (pos = header[10,4].unpack("N").first) == 4294967295 ? -1 : pos
    end

    def initialize_file_header!
      header = "\xff"*HEADER_SIZE
      header[0,4] = MAGIC_SIGNATURE
      header[4,2] = VERSION
      header[6,4] = [record_size].pack("N")
      header[10,4] = [first_available_position].pack("N")
      @bitmap_file.seek(0)
      @bitmap_file.write(header)
    end

    def update_file_header!
      @bitmap_file.seek(10)
      @bitmap_file.write([first_available_position].pack("N"))
    end

    def initialize_file_map!
      extend_map
    end

    def map_size
      return @map_size if @map_size
      pos = @bitmap_file.pos
      @bitmap_file.seek(0,IO::SEEK_END)
      size = @bitmap_file.pos - HEADER_SIZE
      @bitmap_file.seek(pos)
      @map_size = size
    end

    def read_map
      @bitmap_file.seek(HEADER_SIZE)
      @bitmap_file.read(map_size)
    end

    def find_first_available_position
      unless first_available_position == -1
        first_available_position
      else
        byte_num = 0
        byte = nil
        read_map.each_byte do |v|  
          if v != 255
            byte = v
            break
          else
            byte_num += 1 
            false
          end
        end
        if byte 
          byte_offset = byte.to_s(2).ljust(8,'0').index('0')
          return byte_num*8 + byte_offset
        end
        nil
      end
    end

    def decrement_available_capacity!(position)
      byte = read_map_byte(position)
      mask = (1 << (position % 8))
      return unless byte & mask  == 0
        
      write_map_byte(position, byte | mask)

      if read_map_byte(position + 1) == 255
        @first_available_position = -1
      else
        @first_available_position = position + 1
      end
      
      update_file_header!
    end

    def increment_available_capacity!(position)
      update_map_byte!(position) {|byte| byte & (255 ^ (1 << (position % 8))) }
      update_file_header!
    end

    def update_map_byte!(position)
      byte = yield(read_map_byte(position))
      write_map_byte(position,byte)
    end

    def read_map_byte(position)
      extend_map if map_size*8 <= position # TODO: spec it
      @bitmap_file.seek(HEADER_SIZE + position/8)
      @bitmap_file.read(1).unpack('C').first # in Ruby 1.8 we can also do [0] instead of unpack
    end
    
    def write_map_byte(position,byte)
      @bitmap_file.seek(HEADER_SIZE + position/8)
      @bitmap_file.write([byte].pack('C'))
    end

    def write_at_position!(position,record)
      @data_file.seek(position*record_size)
      @data_file.write(record)
    end

    def read_at_position(position)
      @data_file.seek(position*record_size)
      @data_file.read(record_size)
    end
    
    def extend_map
      pos = @bitmap_file.pos
      @bitmap_file.seek(0,IO::SEEK_END)
      @bitmap_file.write("\x00" *(@options['bitmap_extension_pace']||8192))
      @bitmap_file.seek(pos)
      @map_size = nil
    end

  end

end