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

SimpleSkiplist.with_optimizations(OPTIMIZATIONS) do |lang|

  describe "Brand new SkiplistVolume" do
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
  
  describe "Brand new SkiplistVolume with immediate dumps" do
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
  
end