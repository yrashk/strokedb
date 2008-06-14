$:.unshift File.dirname(__FILE__) + "/../../lib"
require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

FileUtils.rm_rf "../../spec/temp/storages/search_bench"
StrokeDB::Config.build :default => true, :base_path => "../../spec/temp/storages/search_bench"

Skiplist.optimize!(:C)

puts "before Meta.new"
User = Meta.new
puts "before User.create!"
1.times {|i| User.create! :i => i }
puts "before User.find"
# Benchmark.bm(17) do |x|
#   GC.start
#   x.report("Search ") do
    1.times do
      User.find :i => 2
    end
#   end
# end
