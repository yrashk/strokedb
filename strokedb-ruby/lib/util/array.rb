module StrokeDB
  class LazyMappingArray < Array
    def initialize(*args,&block)
      @map_proc = block || proc {|v| v}
      super(*args)
    end

    alias :_square_brackets :[]
    def [](*args)
      r = _square_brackets(*args)
      if (args.first.is_a?(Range) || args.size == 2) && r.is_a?(Array)
        Array.new(r).map {|v| @map_proc.call(v) }
      else
        @map_proc.call(r)
      end
    end
    alias :slice :[]
    
    alias :_at :at
    def at(index)
      @map_proc.call(_at(index))
    end

    def first
      at(0)
    end

    def last
      at(size-1)
    end
   
    alias :_each :each
    def each
      _each do |val| 
        block_given? ? yield(@map_proc.call(val)) : val
      end
    end
    
    alias :_map :map
    def map
      _map do |val|
        block_given? ? yield(@map_proc.call(val)) : val
      end
    end
   
    alias :_zip :zip
    def zip(*args)
      map{|v|v}.zip(*args)
    end
    
    def class
      Array
    end
  end
end