module StrokeDB
  class LazyArray < Array
    def initialize(*args)
      @load_with_proc = proc {|v| v}
      super(*args)
    end

    def load_with(&block)
      @load_with_proc = block
      self
    end

    alias :_square_brackets :[]
    def [](*args)
      load!
      _square_brackets(*args)
    end
    alias :slice :[]

    alias :_square_brackets_set :[]=
    def []=(index,value)
      load!
      _square_brackets_set(index,value)
    end

    alias :_at :at
    def at(index)
      load!
      _at(index)
    end

    def first
      at(0)
    end

    def last
      at(size-1)
    end

    alias :_each :each
    def each
      load!
      _each do |val| 
        yield val
      end
    end

    alias :_map :map
    def map
      load!
      _map do |val|
        yield val
      end
    end

    alias :_zip :zip
    def zip(*args)
      map{|v|v}.zip(*args)
    end

    alias :_push :push
    def push(value)
      load!
      _push(value)
    end
    alias :<< :push

    alias :_unshift :unshift
    def unshift(value)
      load!
      _unshift(value)
    end

    alias :_pop :pop
    def pop
      load!
      _pop
    end

    alias :_shift :shift
    def shift
      load!
      _shift
    end

    alias :_find :find
    def find
      load!
      _find {|value| yield(value)}
    end
    
    alias :_inspect :inspect
    def inspect
      load!
      _inspect
    end
    
    alias :_equal :==
    def ==(arr)
      load!
      _equal(arr)
    end
    
    alias :_index :index
    def index(v)
      load!
      _index(v)
    end
    

    def class
      Array
    end

    private

    def load!
      if @load_with_proc
        clear
        class << self
          alias :[] :_square_brackets
          alias :[]= :_square_brackets_set
          alias :at :_at
          alias :each :_each
          alias :map :_map
          alias :zip :_zip
          alias :push :_push
          alias :unshift :_unshift
          alias :pop :_pop
          alias :shift :_shift
          alias :find :_find
          alias :inspect :_inspect
          alias :== :_equal
          alias :index :_index
        end
        concat @load_with_proc.call(self)
        @load_with_proc = nil
      end
    end
  end
end