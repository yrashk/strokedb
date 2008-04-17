unless defined?(BlankSlate)
  class BlankSlate < BasicObject; end if defined?(BasicObject)

  class BlankSlate
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end
end

class BlankSlate
  MethodMapping = {
    '[]' => 'squarebracket',
    '[]=' => 'squarebracket_set',
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

class NewLazyMappingHash < BlankSlate(Hash)
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

class OldLazyMappingHash < Hash
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


require 'benchmark'

N = 50_000

Benchmark.bmbm(30) do |x|
  x.report('OldLazyMappingHash') do
    N.times do
      a = OldLazyMappingHash.new(Hash[1,2,3,4,5,6]).map_with(&proc {|k| {:struct => k}  }).unmap_with(&proc {|k| k.is_a?(Hash) && k[:struct] || k })
      a[1] = { :struct => :x }
      a[{:struct => :x}] = 1
      a.map
    end
  end
  
  x.report('NewLazyMappingHash') do
    N.times do
      a = NewLazyMappingHash.new(Hash[1,2,3,4,5,6]).map_with(&proc {|k| {:struct => k}  }).unmap_with(&proc {|k| k.is_a?(Hash) && k[:struct] || k })
      a[1] = { :struct => :x }
      a[{:struct => :x}] = 1
      a.map
    end
  end
end

__END__

Rehearsal -----------------------------------------------------------------
OldLazyMappingHash              3.020000   0.010000   3.030000 (  3.166527)
NewLazyMappingHash              4.500000   0.010000   4.510000 (  4.762848)
-------------------------------------------------------- total: 7.540000sec

                                    user     system      total        real
OldLazyMappingHash              3.030000   0.020000   3.050000 (  3.230127)
NewLazyMappingHash              4.510000   0.030000   4.540000 (  4.817493)
