module StrokeDB
  class LazyMappingHash < Hash
    def initialize(original = {}, key_mapper = nil, pair_mapper = nil)
      @key_mapper  = key_mapper  || proc {|k| k}
      @pair_mapper = pair_mapper || proc {|k, v| [k, v]}
      super(default)
      original.each {|k,v| self[k] = v } 
    end
    
    alias :_square_brackets :[]
    def [](k)
      k = @key_mapper.call(k)
      r = _square_brackets(k)
      @pair_mapper.call(k, r).last
    end
   
    alias :_each :each
    def each
      _each do |k, v|
        yield(*@pair_mapper.call(k, v))
      end
    end
   
    def class
      Hash
    end
  end
end
