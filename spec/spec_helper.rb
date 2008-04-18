require File.expand_path(File.dirname(__FILE__) + '/../strokedb')
include StrokeDB

def setup_default_store(store=nil)
  if store
    StrokeDB.stub!(:default_store).and_return(store)
    return store
  end
  @mem_storage = StrokeDB::MemoryStorage.new
  @path = File.join(File.dirname(__FILE__), '/../test/storages/spec')
  FileUtils.rm_rf @path
  StrokeDB.stub!(:default_store).and_return(StrokeDB::Store.new(:storage => @mem_storage,:index => @index, 
                                                                :path => @path))
  StrokeDB.default_store
end

def stub_meta_in_store(store=nil)
  store ||= StrokeDB.default_store
  meta = store.find(NIL_UUID)
  store.should_receive(:find).with(NIL_UUID).any_number_of_times.and_return(meta)
  store.should_receive(:include?).with(NIL_UUID).any_number_of_times.and_return(true)
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