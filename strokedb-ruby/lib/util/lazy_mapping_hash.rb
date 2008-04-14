module StrokeDB
  class LazyMappingHash < BlankSlate(Hash)
    def initialize(original = {}, decoder = nil, encoder = nil)
      @decoder = decoder || proc {|v| v}
      @encoder = encoder || proc {|v| v}
      super(default)
      original.each {|k,v| self.__squarebracket_set(k,v) }
    end
    
    def map_with(&block)
      @encoder = block
      self
    end

    def unmap_with(&block)
      @decoder = block
      self
    end

    def class
      Hash
    end

    def method_missing sym, *args, &blk
      super if sym.to_s =~ /^__/
      mname = "__#{::BlankSlate::MethodMapping[sym.to_s] || sym}"

      case sym
      when :keys, :values
        __send__(mname, *args, &blk).map{|v| @encoder.call(v) }

      when :each
        self.__each do |k,v|
          yield @encoder.call(k), @encoder.call(v)
        end

      when :[], :[]=
        args.map!{|v| @decoder.call(v) }
        @encoder.call __send__(mname, *args, &blk)

      else
        __send__(mname, *args, &blk)
      end
    end
  end
end
