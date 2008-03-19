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
    attr_accessor :first_available_position

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
        self.first_available_position = 0
        initialize_file_header!
        initialize_file_map
      else
        @file = File.new(path,'r+')
        self.first_available_position = -1
        read_file_header
        initialize_file_header!
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
      self.first_available_position = (pos = header[18,4].unpack("N").first) == 4294967295 ? -1 : pos
    end

    def initialize_file_header!
      header = "\xff"*HEADER_SIZE
      header[0,4] = MAGIC_SIGNATURE
      header[4,2] = VERSION
      header[6,4] = [record_size].pack("N")
      header[10,4] = [capacity].pack("N")
      header[14,4] = [available_capacity].pack("N")
      header[18,4] = [first_available_position].pack("N")
      @file.seek(0)
      @file.write(header)
    end

    def update_file_header!
      initialize_file_header! # FIXME
    end

    def initialize_file_map
      map = "\x00"*map_size
      @file.seek(HEADER_SIZE)
      @file.write(map)
    end

    def map_size
      @map_size ||= ((record_size*capacity)/8)
    end

    def read_map
      @file.seek(HEADER_SIZE)
      @file.read(map_size)
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
      return unless byte & (1 << (position % 8)) == 0
        
      @available_capacity -= 1
      write_map_byte(position, byte | 1 << (position % 8))

      if read_map_byte(position + 1) == 255
        @first_available_position = -1
      else
        @first_available_position = position + 1
      end
      
      update_file_header!
    end

    def increment_available_capacity!(position)
      @available_capacity += 1
      update_map_byte!(position) {|byte| byte & (255 ^ (1 << (position % 8))) }
      update_file_header!
    end

    def update_map_byte!(position)
      byte = yield(read_map_byte(position))
      write_map_byte(position,byte)
    end

    def read_map_byte(position)
      @file.seek(HEADER_SIZE + position/8)
      @file.read(1).unpack('C').first # in Ruby 1.8 we can also do [0] instead of unpack
    end
    
    def write_map_byte(position,byte)
      @file.seek(HEADER_SIZE + position/8)
      @file.write([byte].pack('C'))
    end

    def write_at_position!(position,record)
      @file.seek(HEADER_SIZE + map_size + position*record_size)
      @file.write(record)
    end

    def read_at_position(position)
      @file.seek(HEADER_SIZE + map_size + position*record_size)
      @file.read(record_size)
    end

  end

end