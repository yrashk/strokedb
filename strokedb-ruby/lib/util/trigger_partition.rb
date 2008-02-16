module Enumerable
  class TriggerPartition
    def initialize(enum, &block)
      @enum = enum
      @cont = block
    end
    def fill(&block)
      @fill = block
      self
    end
    def emit
      partitions = []
      cont = @cont
      fill = @fill
      @enum.inject(nil) do |part, elem|
        if part && cont.call(part, elem)
          fill.call(part, elem)
          part
        else
          partitions << part if part
          yield(elem)
        end
      end
      partitions
    end
  end
  def trigger_partition(&block)
    TriggerPartition.new(self, &block)
  end
end

if __FILE__ == $0
  arr = [1,2,3,4,5, -1, -4, -3, 5, 6, 7, 8, -6, -7]
  parr = arr.trigger_partition do |partition, element|
    partition[0] > 0 && element > 0 || partition[0] < 0 && element < 0
  end.fill do |p, e|
    p << e
  end.emit do |e|
    [e]
  end
  
  p arr
  p parr
  
  require 'benchmark'
  include Benchmark
  n = 1_000
  bm(32) do |x|
    x.report("#{n} times:" ) do
      n.times do
        arr.trigger_partition do |partition, element|
          partition[0] > 0 && element > 0 || partition[0] < 0 && element < 0
        end.fill do |p, e|
          p << e
        end.emit do |e|
          [e]
        end
      end
    end
    arr10 = arr*10
    x.report("#{n} times (x10 larger data):" ) do
      n.times do
        arr10.trigger_partition do |partition, element|
          partition[0] > 0 && element > 0 || partition[0] < 0 && element < 0
        end.fill do |p, e|
          p << e
        end.emit do |e|
          [e]
        end
      end
    end
  end
end
