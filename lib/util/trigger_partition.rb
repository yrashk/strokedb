module Enumerable
  class TriggerPartitionContext
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
      p = @enum.inject(nil) do |part, elem|
        if part && cont.call(part, elem)
          fill.call(part, elem)
          part
        else
          partitions << part if part
          yield(elem)
        end
      end
      partitions << p if p
      partitions
    end
  end
  def trigger_partition(&block)
    TriggerPartitionContext.new(self, &block)
  end
  
  class TriggerPartitions
    def self.partition(list)
      partitions = []
      p = list.inject(nil) do |part, elem|
        if part && continue?(part, elem)
          fill(part, elem)
          part
        else
          partitions << part if part
          emit(elem)
        end
      end
      partitions << p if p
      partitions
    end
    def self.continue?(p, e)
      true
    end
    def self.emit(e)
      [e]
    end
    def self.fill(p, e)
      p << e
    end
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
  
  # Class might be faster
  class SignPartitions < Enumerable::TriggerPartitions
    def self.continue?(partition, element)
      partition[0] > 0 && element > 0 || partition[0] < 0 && element < 0
    end
  end
  
  p Enumerable::TriggerPartitions.partition(arr)
  p SignPartitions.partition(arr)
  
  require 'benchmark'
  include Benchmark
  n = 1000
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
    arrL = arr*28
    x.report("#{n} times (x28 larger data):" ) do
      n.times do
        arrL.trigger_partition do |partition, element|
          partition[0] > 0 && element > 0 || partition[0] < 0 && element < 0
        end.fill do |p, e|
          p << e
        end.emit do |e|
          [e]
        end
      end
    end
    # 35% faster
    x.report("#{n} times (SignPartitions):" ) do
      (n/5).times do
        SignPartitions.partition(arrL)
        SignPartitions.partition(arrL)
        SignPartitions.partition(arrL)
        SignPartitions.partition(arrL)
        SignPartitions.partition(arrL)
      end
    end
    # + 17% faster (relative to SignPartitions)
    x.report("#{n} times (raw code):" ) do
      n.times do
        parts = []
        p = arrL.inject(nil) do |partition, element|
          if partition && (partition[0] > 0 && element > 0 || partition[0] < 0 && element < 0)
            partition << element
            partition
          else
            parts << partition if partition
            [element]
          end
        end
        parts << p if p
      end
    end
  end
end
