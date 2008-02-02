require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '../../../../strokeobject-ruby/strokeobject')

describe "Config" do

  before(:each) do
    @config = StrokeDB::Config.new
    @root_path = 'test/config/'
    @paths = []
  end
  
  it "should be the default config if desired" do
    @config = StrokeDB::Config.new(true)
    ::Stroke.default_config.should == @config
  end
  
  it "should have no storages or indexes on creation" do
    @config.storages.should be_empty
    @config.indexes.should be_empty
  end
  
  it "should add known storages without specific parameters" do
    @config.add_storage :mem, :memory_chunk
    @config.storages[:mem].should be_an_instance_of(MemoryChunkStorage)
  end

  it "should add known storages with specific parameters" do
    @paths << (@root_path + "file_chunk_storage")
    @config.add_storage :fs, :file_chunk, @paths.last
    @config.storages[:fs].should be_an_instance_of(FileChunkStorage)
    @config.storages[:fs].path.should == @paths.last
  end
  
  it "should raise the correct exception when adding an unknown storage" do
    lambda { @config.add_storage :unknown, :unknown_storage_type }.should raise_error(StrokeDB::UnknownStorageTypeError)
  end
  
  it "should chain storages together and declare the authoritative source" do
    @paths << (@root_path + "file_chunk_storage_chain")
    @config.add_storage :mem, :memory_chunk
    @config.add_storage :fs, :file_chunk, @paths.last
    @config.chain :fs, :mem, :authoritative => :fs
    @config.storages[:mem].has_chained_storage?(@config.storages[:fs]).should be_true
    @config.storages[:fs].has_chained_storage?(@config.storages[:mem]).should be_true
    @config.storages[:mem].has_chained_storage?(@config.storages[:mem]).should be_false
    @config.storages[:fs].has_chained_storage?(@config.storages[:fs]).should be_false
    @config.storages[:mem].authoritative_source.should equal(@config.storages[:fs])
    @config.storages[:fs].authoritative_source.should be_nil
  end

  it "should add an index" do
    @paths << (@root_path + "file_chunk_storage_index")
    @config.add_storage :fs, :file_chunk, @paths.last
    @paths << (@root_path + "inverted_list_file_index")
    @config.add_storage :idx_st, :inverted_list_file, @paths.last
    @config.add_index :idx, :inverted_list, :idx_st
    @config.indexes[:idx].should be_an_instance_of(InvertedListIndex)
  end

  it "should raise the correct exception when adding an unknown index" do
    lambda { @config.add_index :unknown, :unknown_index_type, :idx_st }.should raise_error(StrokeDB::UnknownIndexTypeError)
  end

  it "should add a store" do
    @config.add_storage :fs, :file_chunk, 'file_chunk_storage_store'
    @config.add_store :store, :skiplist, :fs, :cut_level => 4
    @config.stores[:store].should be_an_instance_of(SkiplistStore)
  end
  
  it "should add a default store with default index" do
    @paths << (@root_path + "file_chunk_storage_default_index")
    @config.add_storage :fs, :file_chunk, @paths.last
    @paths << (@root_path + "inverted_list_file_default_index")
    @config.add_storage :index_storage, :inverted_list_file, @paths.last
    @config.add_index :default, :inverted_list, :index_storage
    @config.add_store :default, :skiplist, :fs, :cut_level => 4
    @config.stores[:default].should be_an_instance_of(SkiplistStore)
    ::Stroke.default_store.should == @config.stores[:default]
  end

  after(:each) do
    @paths.each {|path| FileUtils.rm_rf path}
  end

end