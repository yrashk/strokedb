begin
  require 'mmap'
  module StrokeDB


    class MmapMapVolume < MapVolume

      def close!
        @mmap.munmap
      end
    
      private
    
      def initialize_file
        unless File.exists?(path)
          File.open(path,'w+').close
          @mmap = Mmap.new(path,'rw', Mmap::MAP_SHARED, :advice => Mmap::MADV_RANDOM)
          @available_capacity = capacity
          @mmap.extend(HEADER_SIZE+map_size)
          initialize_file_header!
          initialize_file_map
        else
          @mmap = Mmap.new(path,'rw', Mmap::MAP_SHARED, :advice => Mmap::MADV_RANDOM)
          read_file_header
        end
      end
    
      def read_file_header
        begin
          header = @mmap[0,HEADER_SIZE]
        rescue TruncatedDataError
          raise InvalidMapVolumeError
        end
        raise InvalidMapVolumeError unless header[0,4] == MAGIC_SIGNATURE
        @options['record_size'] = header[6,4].unpack("N").first
        @options['capacity'] = header[10,4].unpack("N").first
        @available_capacity = header[14,4].unpack("N").first
      end
    
      def initialize_file_header!
        @mmap[0,512] = "\xff"*HEADER_SIZE
        @mmap[0,4] = MAGIC_SIGNATURE
        @mmap[4,2] = VERSION
        @mmap[6,4] = [record_size].pack("N")
        @mmap[10,4] = [capacity].pack("N")
        @mmap[14,4] = [available_capacity].pack("N")
      end
        
      def update_file_header!
        @mmap[14,4] = [available_capacity].pack("N")
      end
    
      def initialize_file_map
        @mmap[HEADER_SIZE,map_size] = "\x00"*map_size
      end
    
      def read_map
        @mmap[HEADER_SIZE,map_size]
      end
    
      def update_map_byte!(position)
        byte = yield(read_map_byte(position))
        @mmap[HEADER_SIZE+position/8] = byte
      end
    
      def read_map_byte(position)
        @mmap[HEADER_SIZE+position/8]
      end

      def write_at_position!(position,record)
        @mmap[HEADER_SIZE + map_size + position*record_size,record_size] = record
      end

      def read_at_position(position)
        @mmap[HEADER_SIZE + map_size + position*record_size,record_size]
      end
    
    end

  end

rescue
end