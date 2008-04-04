require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 


FileUtils.rm_rf "test/storages/bigstore"
StrokeDB::Config.build :default => true, :base_path => "test/storages/bigstore"
StrokeDB.default_store.index_store = nil

N = 1_000

# bm(30) do |x| 
# 
#   x.report("creating #{N} documents...") do
#     N.times do |i|
#       d = Document.create!(:index => i)
#       StrokeDB.default_store.stop_autosync!
#     end
#   end
#   
# end

SimpleSkiplist.optimize!(:C)

# FileUtils.rm_rf "test/storages/bigstore"
# StrokeDB::Config.build :default => true, :base_path => "test/storages/bigstore"


bm(30) do |x| 

  x.report("[C] creating #{N} documents...") do
    N.times do |i|
      d = Document.create!(:index => i)
    end
    StrokeDB.default_store.stop_autosync!

  end
  
end
