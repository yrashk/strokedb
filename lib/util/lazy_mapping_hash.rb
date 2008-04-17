module StrokeDB
  class LazyMappingHash < Hash
    def initialize(original = {}, decoder = nil, encoder = nil)
      @decoder = decoder || proc {|v| v}
      @encoder = encoder || proc {|v| v}
      super(default)
      original.each {|k,v| self[k] = v } 
    end

    def map_with(&block)
      @encoder = block
      self
    end

    def unmap_with(&block)
      @decoder = block
      self
    end

    alias :_square_brackets :[]
    def [](k)
      @encoder.call(_square_brackets(@decoder.call(k)))
    end

    alias :_square_brackets_set :[]=
    def []=(k,v)
      _square_brackets_set(@decoder.call(k),@decoder.call(v))
    end

    alias :_each :each
    def each
      e = @encoder
      _each do |k, v|
        yield(e.call(k), e.call(v))
      end
    end

    alias :_keys :keys
    def keys
      _keys.map {|k| @encoder.call(k)}
    end

    alias :_values :values
    def values
      _values.map {|v| @encoder.call(v)}
    end

    def class
      Hash
    end
  end
end
