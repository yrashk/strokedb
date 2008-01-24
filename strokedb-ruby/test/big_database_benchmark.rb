require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 

storage = FileChunkStorage.new "test/storages/big_storage"
storage.chunks_cache = {}

N = 500

puts "Creating #{N} documents..."

bm(10) do |x| 
  storage.clear!
  store = SkiplistStore.new(storage, 4)
  GC.start
  x.report("Cut level = 4") do
    N.times do |i|
      d = store.new_doc :index => i
      d.save!
    end
  end
  storage.clear!
  store = SkiplistStore.new(storage, 6)
  GC.start
  x.report("Cut level = 6") do
    N.times do |i|
      d = store.new_doc :index => i
      d.save!
    end
  end
end
