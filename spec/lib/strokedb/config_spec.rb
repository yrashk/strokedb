require File.dirname(__FILE__) + '/spec_helper'

describe "Config" do

  before(:each) do
    @config = StrokeDB::Config.new
    @root_path = TEMP_STORAGES + '/config/'
    @paths = []
  end
  
  it "should be the default config if desired" do
    @config = StrokeDB::Config.new(true)
    ::StrokeDB.default_config.should == @config
  end
  
  it "should have no storages on creation" do
    @config.storages.should be_empty
  end
  
  it "should add known storages without specific parameters" do
    @config.add_storage :mem, :memory
    @config.storages[:mem].should be_an_instance_of(MemoryStorage)
  end

  it "should add known storages with specific parameters" do
    @paths << (@root_path + "file_storage")
    @config.add_storage :fs, :file, :path => @paths.last
    @config.storages[:fs].should be_an_instance_of(FileStorage)
    @config.storages[:fs].path.should == @paths.last
  end
  
  it "should raise the correct exception when adding an unknown storage" do
    lambda { @config.add_storage :unknown, :unknown_storage_type }.should raise_error(StrokeDB::UnknownStorageTypeError)
  end
  
  it "should raise an exception on chain with insufficient storages" do
    lambda { @config.chain }.should raise_error
    @config.add_storage :mem, :memory
    lambda { @config.chain :mem }.should raise_error
  end

  it "should raise an exception on chain with undefined storages" do
    lambda { @config.chain :not_here }.should raise_error
  end

  it "should chain storages together" do
    @paths << (@root_path + "file_storage_chain")
    @config.add_storage :mem1, :memory
    @config.add_storage :mem2, :memory
    @config.add_storage :mem3, :memory
    @config.add_storage :fs, :file, :path => @paths.last
    @config.chain :mem1, :mem2, :fs
    @config.chain :mem2, :mem3
    @config.storages[:mem1].should have_chained_storage(@config.storages[:mem2])
    @config.storages[:mem2].should have_chained_storage(@config.storages[:fs])
    @config.storages[:fs].should have_chained_storage(@config.storages[:mem2])
    @config.storages[:mem2].should have_chained_storage(@config.storages[:mem1])
    @config.storages[:mem1].should_not have_chained_storage(@config.storages[:mem1])
    @config.storages[:mem2].should_not have_chained_storage(@config.storages[:mem2])
    @config.storages[:fs].should_not have_chained_storage(@config.storages[:fs])
    @config.storages[:mem1].should_not have_chained_storage(@config.storages[:fs])
    @config.storages[:fs].should_not have_chained_storage(@config.storages[:mem1])
    @config.storages[:mem2].should have_chained_storage(@config.storages[:mem3])
    @config.storages[:mem3].should have_chained_storage(@config.storages[:mem2])
    @config.storages[:mem1].should_not have_chained_storage(@config.storages[:mem3])
    @config.storages[:fs].should_not have_chained_storage(@config.storages[:mem3])
  end

  it "should add a store" do
    @paths << (@root_path + "file_storage")
    @config.add_storage :fs, :file, :path => @paths.last
    @config.add_store :store, nil, :storage => :fs, :cut_level => 4, :path => @paths.last
    @config.stores[:store].should be_an_instance_of(Store)
    @config.stores[:store].storage.should == @config.storages[:fs]
  end
  
  it "should add a default store" do
    @paths << (@root_path + "file_storage_default_index")
    @config.add_storage :fs, :file, :path => @paths.last
    @config.add_store :default, nil, :storage => :fs, :cut_level => 4, :path => @paths.last
    @config.stores[:default].should be_an_instance_of(Store)
  end

  after(:each) do
    @paths.each {|path| FileUtils.rm_rf path}
  end

end

describe "Config builder" do
  
  before(:each) do
    @base_path = TEMP_STORAGES + '/cfg_builder'
    FileUtils.rm_rf @base_path
  end

  after(:each) do
    FileUtils.rm_rf @base_path
  end
  
  it "should make config default if told so" do
    config = StrokeDB::Config.build :default => true, :base_path => @base_path
    StrokeDB.default_config.should == config
  end

  it "should not make config default if told so" do
    config = StrokeDB::Config.build :base_path => @base_path
    StrokeDB.default_config.should_not == config
  end
  
  it "should use Store by default" do
    config = StrokeDB::Config.build :base_path => @base_path
    config.stores[:default].should be_a_kind_of(Store)
  end

  it "should use specified store if told so" do
    StrokeDB.send!(:remove_const,'SomeFunnyStore') if defined?(SomeFunnyStore)
    StrokeDB::SomeFunnyStore = Class.new(Store)
    config = StrokeDB::Config.build :store => :some_funny, :base_path => @base_path
    config.stores[:default].should be_a_kind_of(SomeFunnyStore)
  end

  it "should add storages as he is told to" do
    StrokeDB.send!(:remove_const,'Chunk1Storage') if defined?(Chunk1Storage)
    StrokeDB.send!(:remove_const,'Chunk2Storage') if defined?(Chunk2Storage)
    StrokeDB::Chunk1Storage = Class.new(MemoryStorage)
    StrokeDB::Chunk2Storage = Class.new(MemoryStorage)
    config = StrokeDB::Config.build :storages => [:chunk_1,:chunk_2], :base_path => @base_path
    config.storages[:chunk_1].should be_a_kind_of(Chunk1Storage)
    config.storages[:chunk_2].should be_a_kind_of(Chunk2Storage)
  end
  
  it "should initialize all storages with base_path+storage_name" do
    StrokeDB.send!(:remove_const,'Chunk1Storage') if defined?(Chunk1Storage)
    StrokeDB.send!(:remove_const,'Chunk2Storage') if defined?(Chunk2Storage)
    StrokeDB::Chunk1Storage = Class.new(MemoryStorage)
    StrokeDB::Chunk2Storage = Class.new(MemoryStorage)
    Chunk1Storage.should_receive(:new).with(:path => @base_path + '/chunk_1').and_return(MemoryStorage.new)
    Chunk2Storage.should_receive(:new).with(:path => @base_path + '/chunk_2').and_return(MemoryStorage.new)
    config = StrokeDB::Config.build :storages => [:chunk_1,:chunk_2], :base_path => @base_path
  end
  
  it "should add :memory and :file by default" do
    config = StrokeDB::Config.build :base_path => @base_path
    config.storages[:memory].should be_a_kind_of(MemoryStorage)
    config.storages[:file].should be_a_kind_of(FileStorage)
  end

  it "should chain given storages sequentially" do
    StrokeDB.send!(:remove_const,'Chunk1Storage') if defined?(Chunk1Storage)
    StrokeDB.send!(:remove_const,'Chunk2Storage') if defined?(Chunk2Storage)
    StrokeDB.send!(:remove_const,'Chunk3Storage') if defined?(Chunk3Storage)
    StrokeDB::Chunk1Storage = Class.new(MemoryStorage)
    StrokeDB::Chunk2Storage = Class.new(MemoryStorage)
    StrokeDB::Chunk3Storage = Class.new(MemoryStorage)
    config = StrokeDB::Config.build :storages => [:chunk_1,:chunk_2,:chunk_3], :base_path => @base_path
    config.storages[:chunk_1].should have_chained_storage(config[:chunk_2])
    config.storages[:chunk_2].should have_chained_storage(config[:chunk_1])
    config.storages[:chunk_3].should have_chained_storage(config[:chunk_2])
    config.storages[:chunk_2].should have_chained_storage(config[:chunk_3])
  end

  it "should set authoritative sources for storages sequentially" do
    StrokeDB.send!(:remove_const,'Chunk1Storage') if defined?(Chunk1Storage)
    StrokeDB.send!(:remove_const,'Chunk2Storage') if defined?(Chunk2Storage)
    StrokeDB.send!(:remove_const,'Chunk3Storage') if defined?(Chunk3Storage)
    StrokeDB::Chunk1Storage = Class.new(MemoryStorage)
    StrokeDB::Chunk2Storage = Class.new(MemoryStorage)
    StrokeDB::Chunk3Storage = Class.new(MemoryStorage)
    config = StrokeDB::Config.build :storages => [:chunk_1,:chunk_2,:chunk_3], :base_path => @base_path
    config.storages[:chunk_1].authoritative_source.should == config[:chunk_2]
    config.storages[:chunk_2].authoritative_source.should == config[:chunk_3]
    config.storages[:chunk_3].authoritative_source.should be_nil
  end
  
  it "should dump config in base_path (except 'default' key)" do
    cfg = StrokeDB::Config.build :default => true, :base_path => @base_path
    config = JSON.parse(IO.read(@base_path + '/config'))
    config.should == cfg.build_config
  end

  it "should load dumped config" do
    cfg = StrokeDB::Config.build :default => true, :base_path => @base_path
    cfg.storages.values.each {|s| s.close! if s.respond_to?(:close!)}
    config = JSON.parse(IO.read(@base_path + '/config'))
    cfg = StrokeDB::Config.load(@base_path + '/config')
    cfg.build_config.should == config
    cfg.should_not == StrokeDB.default_config
  end
  
  it "should load dumped config and make it default if told so" do
    cfg = StrokeDB::Config.build :default => true, :base_path => @base_path
    cfg.storages.values.each {|s| s.close! if s.respond_to?(:close!)}
    config = JSON.parse(IO.read(@base_path + '/config'))
    cfg = StrokeDB::Config.load(@base_path + '/config',true)
    cfg.build_config.should == config
    cfg.should == StrokeDB.default_config
  end
    
end
