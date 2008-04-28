require File.dirname(__FILE__) + '/spec_helper'

describe "SkiplistVolume inserts and finds", :shared => true do
  it "should find & insert some data" do
    @volume.find("key").should == nil
    @volume.insert("key", "value")
    @volume.find("key").should == "value"
    @volume.insert("key2", "value2")
    @volume.find("key").should == "value"
    @volume.find("key2").should == "value2"
    @volume.insert("key", nil)
    @volume.find("key").should == nil
    @volume.find("key2").should == "value2"
  end
end

#SimpleSkiplist.with_optimizations(OPTIMIZATIONS) do |lang|
lang = "Ruby {FIXME: with_optimizations is irreversible operation for now}"
  describe "Brand new SkiplistVolume [#{lang}]" do
    before(:each) do
      @path = TEMP_STORAGES + '/skiplist_volume_files/volume'
      FileUtils.rm_rf(TEMP_STORAGES + '/skiplist_volume_files')
      @volume = SkiplistVolume.new(:path => @path, :max_log_size => 1024, :silent => true)
    end
    
    it "should be empty" do
      @volume.should be_empty
    end
    
    it_should_behave_like "SkiplistVolume inserts and finds"
  end
  
  describe "Brand new SkiplistVolume with immediate dumps [#{lang}]" do
    before(:each) do
      @path = TEMP_STORAGES + '/skiplist_volume_files/volume'
      FileUtils.rm_rf(TEMP_STORAGES + '/skiplist_volume_files')
      @volume = SkiplistVolume.new(:path => @path, :max_log_size => 0, :silent => true)
    end
    
    it "should be empty" do
      @volume.should be_empty
    end
    
    it_should_behave_like "SkiplistVolume inserts and finds"
  end
  
  describe "Dumping SkiplistVolume" do
    before(:each) do
      @path = TEMP_STORAGES + '/skiplist_volume_files/volume'
      FileUtils.rm_rf(TEMP_STORAGES + '/skiplist_volume_files')
      @volume = SkiplistVolume.new(:path => @path, :max_log_size => 1024, :silent => true)
    end
    
    it "should dump and load the dumped list" do
      @volume.insert("k",  "v")
      @volume.insert("k2", "v2")
      
      @volume.close!
      @volume.find("k").should  == "v"
      @volume.find("k2").should  == "v2"
      
      lambda { @volume.insert("k3", "v3") }.should raise_error(SkiplistVolume::VolumeClosedException)
      @volume.find("k3").should  == nil
      
      @volume = SkiplistVolume.new(:path => @path, :max_log_size => 1024, :silent => true)
      @volume.find("k").should  == "v"
      @volume.find("k2").should == "v2"
      @volume.find("k3").should == nil
    end
    
    it "should store a lot of values" do
      @arr = (1..1000).to_a.map{|a| a.to_s}.sort
      
      @arr.each{|e| @volume.insert(e,e) }
      
      @volume.close!
      @volume = SkiplistVolume.new(:path => @path, :max_log_size => 1024, :silent => true)
      
      @arr.each{|e| @volume.find(e).should == e }

    end
  end
  
  describe "SkiplistVolume errors" do
    it "should throw an exception if the message is too big" do
      @volume = init_volume
      lambda { 
        @volume.insert("key", "a"*SkiplistVolume::MAX_LOG_MSG_LENGTH)
      }.should raise_error(SkiplistVolume::MessageTooBig)
    end
    
    def init_volume
      @path = TEMP_STORAGES + '/skiplist_volume_files/volume'
      FileUtils.rm_rf(TEMP_STORAGES + '/skiplist_volume_files')
      SkiplistVolume.new(:path => @path, :max_log_size => 1024, :silent => true)
    end
    
  end

#end