$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 

$f_storage = FileChunkStorage.new :path =>  "../../spec/temp/storages/rw_bench_storage"
$f_storage.clear!
$storage = MemoryChunkStorage.new
$storage.add_chained_storage!($f_storage)
store = SkiplistStore.new(:storage => $storage, :cut_level => 4)
f_store = SkiplistStore.new(:storage => $f_storage, :cut_level => 4)

def test_storage(bm, n, title, &block)
  $storage.clear!
  GC.start
  bm.report(title) do
    n.times &block
  end
end

N = 1000
M = 10
bm(28) do |x| 
  
  test_storage x, N/100, "Write (#{N/100} documents)       " do |i|
    d = Document.create!(f_store, :index => i)
  end
  
  some_random_uuids = []
  all_docs = []
  test_storage x, N,     "Write (#{N} with cache)     " do |i|
    d = Document.create!(store, :index => i)
    some_random_uuids << d.uuid if some_random_uuids.size < M
    all_docs << d.uuid
  end
  
  $storage.sync_chained_storages!
  
  GC.start
  x.report(          "Read (#{M} docs #{N} times) ") do
    N.times do
      some_random_uuids.each do |uuid|
        store.find(uuid)
      end
    end
  end
  GC.start
  x.report(          "Read (#{N} docs #{M} times) ") do
    M.times do
      all_docs.each do |uuid|
        store.find(uuid)
      end
    end
  end
  
end
