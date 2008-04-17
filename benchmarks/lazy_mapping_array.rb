unless defined?(BlankSlate)
  class BlankSlate < BasicObject; end if defined?(BasicObject)

  class BlankSlate
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end
end

class BlankSlate
  MethodMapping = {
    '[]' => 'squarebracket',
    '[]=' => 'squarebracket=',
    '<<' => 'leftarrow',
    '*' => 'star',
    '+' => 'plus',
    '-' => 'minus',
    '&' => 'bitwiseand',
    '|' => 'bitwiseor',
    '<=>' => 'spaceship',
    '==' => 'equalequal',
    '===' => 'tripleequal',
    '=~' => 'regexmatch'
  } unless defined? MethodMapping
end

def BlankSlate superclass = nil
  if superclass
    (@blank_slates ||= {})[superclass] ||= Class.new(superclass) do
      instance_methods.sort.each { |m|
        unless m =~ /^__/
          mname = "__#{::BlankSlate::MethodMapping[m.to_s] || m}"
          class_eval "alias #{mname} #{m}"
          undef_method m
        end
      }
    end
  else
    BlankSlate
  end
end

class NewLazyMappingArray < BlankSlate(Array)
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

  def class
    Array
  end

  def method_missing sym, *args, &blk
    mname = "__#{::BlankSlate::MethodMapping[sym.to_s] || sym}"

    case sym
    when :push, :unshift, :<<, :[]=, :index, :-
      last = args.pop
      last = last.is_a?(Array) ? last.map{|v| @unmap_proc.call(v) } : @unmap_proc.call(last)
      args.push last

      __send__(mname, *args, &blk)

    when :[], :slice, :at, :map, :shift, :pop, :include?, :last, :first, :zip, :each, :inject, :each_with_index
      __map{|v| @map_proc.call(v) }.__send__(sym, *args, &blk)

    else
      __send__(mname, *args, &blk)
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

class TestLazyMappingArray < Array

  MethodMapping = {
    '[]' => 'squarebracket',
    '[]=' => 'squarebracket=',
    '<<' => 'leftarrow',
    '&' => 'bitwiseand',
    '*' => 'star',
    '+' => 'plus',
    '-' => 'minus',
    '|' => 'bitwiseor',
    '<=>' => 'spaceship',
    '==' => 'equalequal',
    '===' => 'tripleequal',
    '=~' => 'regexmatch'
  }

  instance_methods.sort.each { |m|
    unless m =~ /^__/
      mname = "__#{MethodMapping[m.to_s] || m}"
      class_eval "alias #{mname} #{m}"
      undef_method m
    end
  }

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

  def class
    Array
  end

  def method_missing sym, *args, &blk
    mname = "__#{MethodMapping[sym.to_s] || sym}"

    case sym
    when :push, :unshift, :<<, :[]=, :index, :-
      last = args.pop
      last = last.is_a?(Array) ? last.map{|v| @unmap_proc.call(v) } : @unmap_proc.call(last)
      args.push last

      __send__(mname, *args, &blk)

    when :[], :slice, :at, :map, :shift, :pop, :include?, :last, :first, :zip, :each, :inject, :each_with_index
      __map{|v| @map_proc.call(v) }.__send__(sym, *args, &blk)

    else
      __send__(mname, *args, &blk)
    end
  end
end


require 'benchmark'

N = 50_000

Benchmark.bmbm(30) do |x|
  [OldLazyMappingArray, NewLazyMappingArray].each do |cls|
    x.report(cls.name) do
      N.times do
        a = cls.new([1,2,3,[1],[2]]).map_with(&proc {|arg| arg.to_s }).unmap_with(&proc {|arg| arg.to_i })
        a.push "1"
        a[2] = "11"
        a[1..2]
      end
    end
  end
end

__END__

Rehearsal -----------------------------------------------------------------
OldLazyMappingArray             1.820000   0.010000   1.830000 (  1.921744)
NewLazyMappingArray             2.620000   0.010000   2.630000 (  2.990501)
-------------------------------------------------------- total: 4.460000sec

                                    user     system      total        real
OldLazyMappingArray             1.870000   0.020000   1.890000 (  2.390068)
NewLazyMappingArray             2.620000   0.030000   2.650000 (  3.072459)
