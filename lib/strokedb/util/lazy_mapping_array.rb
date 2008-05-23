module StrokeDB
  # Lazy loads items from array applying procs on each read and write.
  #
  # Example:
  #
  # @ary[i] = 10
  #
  # applies "unmap proc" to new item value.
  #
  # @ary.at(i)
  #
  # applies "map proc" to value just have been read.
  #
  # StrokeDB uses this class to "follow" links to other documents
  # found in slots in a lazy manner.
  #
  # player:
  #   model: [@#8b195509-f9c4-4fea-90c9-425b38bdda3e.ea5eda78-d410-44be-8b14-f4e33f6fa047]
  #   generation: 4
  #
  # when model collection item is fetched, reference followed and turned into document
  # instance with mapping proc of lazy mapping array.
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
        LazyMappingArray.new(r).map_with(&@map_proc).unmap_with(&@unmap_proc)
      else
        @map_proc.call(r)
      end
    end
    alias :slice :[]

    alias :_square_brackets_set :[]=
    def []=(*args)
      value = args.pop
      if (args.first.is_a?(Range) || args.size == 2) && value.is_a?(Array)
        args << value.map{|e| @unmap_proc.call(e) }
        _square_brackets_set(*args)
      else
        _square_brackets_set(args[0], @unmap_proc.call(value))
      end
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

    alias :_find :find
    def find
      _find {|value| yield(@map_proc.call(value))}
    end

    alias :_index :index
    def index(v)
      _index(@unmap_proc.call(v))
    end

    alias :_substract :-
    def -(a)
      _substract(a.map {|v| @unmap_proc.call(v) })
    end

    alias :_include? :include?
    def include?(v)
      _include?(@unmap_proc.call(v))
    end

    def to_a
       Array.new(map{|v| v})
    end
    
    def ==(arr)
      to_a == arr
    end

    def class
      Array
    end
  end
end
