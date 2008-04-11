unless defined?(BlankSlate)
  class BlankSlate < BasicObject; end if defined?(BasicObject)

  class BlankSlate
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end
end

class NewLazyMappingArray < BlankSlate
  def initialize(*args)
    @map_proc = proc {|v| v}
    @unmap_proc = proc {|v| v}
    @array = Array.new(*args)
  end

  def map_with(&block)
    @map_proc = block
    self
  end

  def unmap_with(&block)
    @unmap_proc = block
    self
  end
  
  def class
    Array
  end
  
  def to_ary
    @array
  end
  alias :to_a :to_ary

  def method_missing sym, *args, &blk
    case sym
    when :push, :unshift, :<<, :[]=, :index, :-
      last = args.pop
      last = last.is_a?(Array) ? last.map{|v| @unmap_proc.call(v) } : @unmap_proc.call(last)
      args.push last

      @array.__send__(sym, *args, &blk)

    else
      @array.map{|v| @map_proc.call(v) }.__send__(sym, *args, &blk)
    end
  end
end

class OldLazyMappingArray < Array
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
      OldLazyMappingArray.new(r).map_with(&@map_proc).unmap_with(&@unmap_proc)
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
  
  def class
    Array
  end
end

require 'benchmark'

N = 100_000

Benchmark.bmbm(30) do |x|
  x.report('old') do
    N.times do
      a = OldLazyMappingArray.new([1,2,3,[1],[2]]).map_with(&proc {|arg| arg.to_s }).unmap_with(&proc {|arg| arg.to_i })
      a.push "1"
      a[2] = "11"
      a[1..2]
    end
  end
  
  x.report('new') do
    a = NewLazyMappingArray.new([1,2,3,[1],[2]]).map_with(&proc {|arg| arg.to_s }).unmap_with(&proc {|arg| arg.to_i })
    a.push "1"
    a[2] = "11"
    a[1..2]
  end
end

__END__

Rehearsal -----------------------------------------------------------------
old                             4.080000   0.000000   4.080000 (  4.098574)
new                             0.000000   0.000000   0.000000 (  0.000062)
-------------------------------------------------------- total: 4.080000sec

                                    user     system      total        real
old                             4.090000   0.000000   4.090000 (  4.087785)
new                             0.000000   0.000000   0.000000 (  0.000062)