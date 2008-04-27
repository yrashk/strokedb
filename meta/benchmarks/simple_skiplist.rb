$:.unshift File.dirname(__FILE__) + "/../../lib"
require 'strokedb'
require 'benchmark'
include StrokeDB

puts "Serialization techniques"

len = 2_000
array = (1..len).map{ [rand(len).to_s]*2 }
biglist = SimpleSkiplist.from_a(array)
dumped = biglist.marshal_dump

Benchmark.bm(17) do |x|
  # First technique: to_a/from_a
  GC.start
  x.report("SimpleSkiplist#to_a          ") do
    biglist.to_a
    biglist.to_a
    biglist.to_a
    biglist.to_a
    biglist.to_a
  end
  GC.start
  x.report("SimpleSkiplist.from_a        ") do
    SimpleSkiplist.from_a(array)
    SimpleSkiplist.from_a(array)
    SimpleSkiplist.from_a(array)
    SimpleSkiplist.from_a(array)
    SimpleSkiplist.from_a(array)
  end

  # Another technique: Marshal.dump
  GC.start
  x.report("SimpleSkiplist#marshal_dump  ") do
    biglist.marshal_dump
    biglist.marshal_dump
    biglist.marshal_dump
    biglist.marshal_dump
    biglist.marshal_dump
  end
  GC.start
  x.report("SimpleSkiplist#marshal_load  ") do
    SimpleSkiplist.allocate.marshal_load(dumped.dup)
    SimpleSkiplist.allocate.marshal_load(dumped.dup)
    SimpleSkiplist.allocate.marshal_load(dumped.dup)
    SimpleSkiplist.allocate.marshal_load(dumped.dup)
    SimpleSkiplist.allocate.marshal_load(dumped.dup)
  end
end

puts
puts "Find/insert techniques"
Benchmark.bm(42) do |x|
  langs = [:C]    if RUBY_PLATFORM !~ /java/
  langs = [:Java] if RUBY_PLATFORM =~ /java/
  SimpleSkiplist.with_optimizations(langs) do |lang|
    GC.start
    x.report("SimpleSkiplist#find 5000 #{lang}".ljust(32)) do 
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
    x.report("SimpleSkiplist#insert 5000 #{lang}".ljust(32)) do 
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
