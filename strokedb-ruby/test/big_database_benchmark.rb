require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 

$m_storage = MemoryChunkStorage.new 
$storage = FileChunkStorage.new "test/storages/big_storage"
$m_storage.add_chained_storage!($storage)

def test_cut_level(bm, n, cutlevel, &block)
  $m_storage.clear!
  $storage.clear!
  $store = SkiplistStore.new($m_storage, cutlevel)
  GC.start
  bm.report("Cut level = #{cutlevel}") do
    n.times &block
    $m_storage.sync_chained_storages!
  end
end

N = 2_000

puts "Creating #{N} documents..."

bm(10) do |x| 
  
  test_cut_level(x, N, 4) do |i|
    d = $store.new_doc :index => i
    d.save!
  end  

  test_cut_level(x, N, 6) do |i|
    
    d = $store.new_doc :index => i
    d.save!
  end  
  
  test_cut_level(x, N, 8) do |i|

    d = $store.new_doc :index => i
    d.save!
  end

end
