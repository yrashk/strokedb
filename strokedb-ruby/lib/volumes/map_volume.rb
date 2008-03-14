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
    
    attr_reader :available_capacity

    def initialize(options = {})
      @options = options.stringify_keys
      initialize_file
    end

    def insert!(record)
      raise MapVolumeCapacityExceeded if available_capacity == 0
      position = find_first_available_position
      write!(position,record)
    end
    
    def write!(position,record)
      raise InvalidRecordSizeError if record.size != record_size
      decrement_available_capacity!(position) if available?(position)
      @file.seek(HEADER_SIZE + map_size + position*record_size)
      @file.write(record)
      position
    end
    
    def read(position)
      raise InvalidRecordPositionError if available?(position)
      @file.seek(HEADER_SIZE + map_size + position*record_size)
      @file.read(record_size)
    end

    def delete!(position)
      increment_available_capacity!(position)
    end
    
    def available?(position)
      read_map_byte(position) & (1 << (position % 8)) == 0
    end
    
    def empty?
      available_capacity == capacity
    end

    def record_size
      @options['record_size']
    end

    def capacity
      @options['capacity']
    end

    def path
      @options['path']
    end

    def close!
      @file.close
    end

    private

    def initialize_file
      unless File.exists?(path)
        @file = File.new(path,'w+')
        @available_capacity = capacity
        write_file_header!
        initialize_file_map
      else
        @file = File.new(path,'r+')
        read_file_header
      end
    end

    def read_file_header
      @file.seek(0)
      begin
        header = @file.readbytes(HEADER_SIZE)
      rescue TruncatedDataError
        raise InvalidMapVolumeError
      end
      raise InvalidMapVolumeError unless header[0,4] = MAGIC_SIGNATURE
      @options['record_size'] = header[6,4].unpack("N").first
      @options['capacity'] = header[10,4].unpack("N").first
      @available_capacity = header[14,4].unpack("N").first
    end
    
    def write_file_header!
      header = "\x00"*HEADER_SIZE
      header[0,4] = MAGIC_SIGNATURE
      header[4,2] = VERSION
      header[6,4] = [record_size].pack("N")
      header[10,4] = [capacity].pack("N")
      header[14,4] = [available_capacity].pack("N")
      @file.seek(0)
      @file.write(header)
    end

    def initialize_file_map
      map = "\x00"*map_size
      @file.seek(HEADER_SIZE)
      @file.write(map)
    end

    def map_size
      ((record_size*capacity)/8)
    end

    def find_first_available_position
      @file.seek(HEADER_SIZE)
      map = @file.read(map_size)
      byte_num = 0
      byte = map.unpack("C*").find do |v|  
        if v != 255
          v
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
        
    def decrement_available_capacity!(position)
      @available_capacity -= 1
      update_map_byte(position) {|byte| byte | 1 << (position % 8) }
      write_file_header!
    end

    def increment_available_capacity!(position)
      @available_capacity += 1
      update_map_byte(position) {|byte| byte & (255 ^ (1 << (position % 8))) }
      write_file_header!
    end

    def update_map_byte(position)
      byte = yield(read_map_byte(position))
      @file.seek(HEADER_SIZE + position/8)
      @file.write([byte].pack('C'))
    end
   
    def read_map_byte(position)
      @file.seek(HEADER_SIZE + position/8)
      @file.read(1).unpack('C').first # in Ruby 1.8 we can also do [0] instead of unpack
    end

  end

end