module StrokeDB
  class LazyMappingArray < Array
    def initialize(*args)
      @map_proc = proc {|v| v}
      @unmap_proc = proc {|v| v}
      super(*args)
    end

    def map_with(&block)
      @map_proc = block
      self
    end
    
    def unmap_with(&block)
      @unmap_proc = block
      self
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
    
    alias :_square_brackets_set :[]=
    def []=(index,value)
      _square_brackets_set(index,@unmap_proc.call(value))
    end
    
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
        yield @map_proc.call(val)
      end
    end
    
    alias :_map :map
    def map
      _map do |val|
        yield @map_proc.call(val)
      end
    end
   
    alias :_zip :zip
    def zip(*args)
      map{|v|v}.zip(*args)
    end
    
    alias :_push :push
    def push(value)
      _push(@unmap_proc.call(value))
    end
    alias :<< :push

    alias :_unshift :unshift
    def unshift(value)
      _unshift(@unmap_proc.call(value))
    end

    alias :_pop :pop
    def pop
      @map_proc.call(_pop)
    end

    alias :_shift :shift
    def shift
      @map_proc.call(_shift)
    end
    
    
    
    def class
      Array
    end
  end
end