module StrokeDB
  module Index

    #
    # H index is built over data's SHA-256 and offset pairs
    #
    class H

      def initialize
        @skiplist = SimpleSkiplist.new
        @cache = {}
      end
      
      def insert(data,offset)
        @skiplist.insert(Util.sha(data),offset)
      end
      
      def find(data)
        @skiplist.find(Util.sha(data))
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