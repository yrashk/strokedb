module StrokeDB
  class LazyMappingHash < Hash
    def initialize(original = {}, decoder = nil, encoder = nil)
      @decoder = decoder || proc {|v| v}
      @encoder = encoder || proc {|v| v}
      super(default)
      original.each {|k,v| self[k] = v } 
    end
    
    alias :_square_brackets :[]
    def [](k)
      @encoder.call(_square_brackets(@decoder.call(k)))
    end
   
    alias :_each :each
    def each
      e = @encoder
      _each do |k, v|
        yield(e.call(k), e.call(v))
      end
    end
   
    def class
      Hash
    end
  end
end
