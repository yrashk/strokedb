require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 

$storage = FileChunkStorage.new "test/storages/big_storage"
$storage.chunks_cache = {}

def test_cut_level(bm, n, cutlevel, &block)
  $storage.clear!
  $store = SkiplistStore.new($storage, cutlevel)
  GC.start
  bm.report("Cut level = #{cutlevel}") do
    n.times &block
    $storage.flush!
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
