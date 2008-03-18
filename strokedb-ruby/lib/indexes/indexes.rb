module StrokeDB
  module Index

    #
    # H index is built over data's SHA-256 and offset pairs
    #
    class H

      def initialize(options = {})
        @options = options.stringify_keys
        @skiplist = FixedLengthSkiplistVolume.new(:path => File.join(@options['path'],'hindexvol'), 
                                                  :key_length => 64, :value_length => 4, :capacity => 100000)
        @cache = {}
      end
      
      def insert(data,offset)
        @skiplist.insert(Util.sha(data),[offset].pack('N'))
      end
      
      def find(data)
        if result = @skiplist.find(Util.sha(data))
          result.unpack('N')
        else
          nil
        end
      end



    end
    
    #
    # IL index is built over atomic objects
    #
    class IL
      def initialize(dv)
        @skiplist = SimpleSkiplist.new
        @datavolume = dv
      end
      def insert(label, value, offset)
        @skiplist.insert(key(label,value), offset)
      end
      def find(label, value)
        @skiplist.find(key(label,value))
      end
      
      private
      
      def key(label,value)
        @datavolume.insert!(label) + @datavolume.insert!(value)
      end
    end

  end
end