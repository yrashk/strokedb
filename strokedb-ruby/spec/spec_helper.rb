require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../strokedb')
include StrokeDB

def setup_default_store(store=nil)
  if store
    StrokeDB.stub!(:default_store).and_return(store)
    return store
  end
  @mem_storage = StrokeDB::MemoryChunkStorage.new
  StrokeDB.stub!(:default_store).and_return(StrokeDB::SkiplistStore.new(:storage => @mem_storage,:index => @index))
  StrokeDB.default_store
end

def stub_meta_in_store(store=nil)
  store ||= StrokeDB.default_store
  meta = store.find(NIL_UUID)
  store.should_receive(:find).with(NIL_UUID).any_number_of_times.and_return(meta)
  store.should_receive(:exists?).with(NIL_UUID).any_number_of_times.and_return(true)
end

def setup_index(store=nil)
  store ||= StrokeDB.default_store
  index_storage = StrokeDB::InvertedListFileStorage.new(:path => 'test/storages/inverted_list_storage')
  index_storage.clear!
  @index = StrokeDB::InvertedListIndex.new(index_storage)
  @index.document_store = store
  store.index_store = @index
  @index
end

def should_merge(base, a, b, r)
  c, r1, r2 = base.stroke_merge(base.stroke_diff(a), base.stroke_diff(b))
  c.should be_false
  r1.should == r
  r2.should == r
  # another order
  c, r1, r2 = base.stroke_merge(base.stroke_diff(b), base.stroke_diff(a))
  c.should be_false
  r1.should == r
  r2.should == r
end

def should_yield_conflict(base, a, b, ra, rb)
  c, r1, r2 = base.stroke_merge(base.stroke_diff(a), base.stroke_diff(b))
  c.should be_true
  r1.should == ra
  r2.should == rb
  # another order
  c, r1, r2 = base.stroke_merge(base.stroke_diff(b), base.stroke_diff(a))
  c.should be_true
  r1.should == rb
  r2.should == ra
end

