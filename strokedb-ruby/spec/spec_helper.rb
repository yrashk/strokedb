require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../strokedb')
include StrokeDB

def setup_default_store(store=nil)
  if store
    StrokeDB.stub!(:default_store).and_return(store)
    return store
  end
  @mem_storage = StrokeDB::MemoryChunkStorage.new
  StrokeDB.stub!(:default_store).and_return(StrokeDB::SkiplistStore.new(@mem_storage,6,@index))
  StrokeDB.default_store
end

def stub_meta_in_store(store=nil)
  store ||= StrokeDB.default_store
  meta = store.find(NIL_UUID)
  store.should_receive(:find).with(NIL_UUID).any_number_of_times.and_return(meta)
  store.should_receive(:exists?).with(NIL_UUID).any_number_of_times.and_return(true)
end

