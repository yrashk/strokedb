require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 

$m_storage = MemoryChunkStorage.new 
$storage = FileChunkStorage.new :path => "test/storages/big_storage"
$m_storage.add_chained_storage!($storage)

def test_cut_level(bm, n, cutlevel, &block)
  $m_storage.clear!
  $storage.clear!
  $store = SkiplistStore.new(:storage => $m_storage, :cut_level => cutlevel)
  GC.start
  bm.report("Cut level = #{cutlevel}") do
    n.times &block
  end
end

N = 2_000

puts "Creating #{N} documents..."

bm(10) do |x| 
  
  test_cut_level(x, N, 4) do |i|
    d = Document.create!($store, :index => i)
  end  

  test_cut_level(x, N, 6) do |i|
    d = Document.create!($store, :index => i)
  end  
  
  test_cut_level(x, N, 8) do |i|
    d = Document.create!($store, :index => i)
  end

end
