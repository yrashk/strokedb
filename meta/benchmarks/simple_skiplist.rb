$:.unshift File.dirname(__FILE__) + "/../../lib"
require 'strokedb'
require 'benchmark'
include StrokeDB

puts "Serialization techniques"

len = 2_000
array = (1..len).map{ [rand(len).to_s]*2 }
biglist = Skiplist.from_a(array)
dumped = biglist.marshal_dump

Benchmark.bm(17) do |x|
  # First technique: to_a/from_a
  GC.start
  x.report("Skiplist#to_a          ") do
    biglist.to_a
    biglist.to_a
    biglist.to_a
    biglist.to_a
    biglist.to_a
  end
  GC.start
  x.report("Skiplist.from_a        ") do
    Skiplist.from_a(array)
    Skiplist.from_a(array)
    Skiplist.from_a(array)
    Skiplist.from_a(array)
    Skiplist.from_a(array)
  end

  # Another technique: Marshal.dump
  GC.start
  x.report("Skiplist#marshal_dump  ") do
    biglist.marshal_dump
    biglist.marshal_dump
    biglist.marshal_dump
    biglist.marshal_dump
    biglist.marshal_dump
  end
  GC.start
  x.report("Skiplist#marshal_load  ") do
    Skiplist.allocate.marshal_load(dumped.dup)
    Skiplist.allocate.marshal_load(dumped.dup)
    Skiplist.allocate.marshal_load(dumped.dup)
    Skiplist.allocate.marshal_load(dumped.dup)
    Skiplist.allocate.marshal_load(dumped.dup)
  end
end

puts
puts "Find/insert techniques"
Benchmark.bm(42) do |x|
  langs = [:C]    if RUBY_PLATFORM !~ /java/
  langs = [:Java] if RUBY_PLATFORM =~ /java/
  Skiplist.with_optimizations(langs) do |lang|
    GC.start
    x.report("Skiplist#find 5000 #{lang}".ljust(32)) do 
      1000.times do
        key = rand(len).to_s
        biglist.find(key)
        biglist.find(key)
        biglist.find(key)
        biglist.find(key)
        biglist.find(key)
      end
    end
    GC.start
    x.report("Skiplist#insert 5000 #{lang}".ljust(32)) do 
      1000.times do
        key = rand(len).to_s
        biglist.insert(key, key)
        key = rand(len).to_s
        biglist.insert(key, key)
        key = rand(len).to_s
        biglist.insert(key, key)
        key = rand(len).to_s
        biglist.insert(key, key)
        key = rand(len).to_s
        biglist.insert(key, key)
      end
    end
  end
end
