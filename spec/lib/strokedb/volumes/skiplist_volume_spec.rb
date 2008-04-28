require File.dirname(__FILE__) + '/spec_helper'

SimpleSkiplist.with_optimizations(OPTIMIZATIONS) do |lang|

  describe "Empty SkiplistVolume [#{lang}]" do

    before(:each) do
      @path = TEMP_STORAGES + '/skiplist_volume_files/volume'
      FileUtils.rm_rf(TEMP_STORAGES + '/skiplist_volume_files')
      @volume = SkiplistVolume.new(:path => @path, :max_log_size => 1024, :silent => true)
    end

    it "should be empty" do
      @volume.should be_empty
    end

    it "should find nil in a empty skiplist" do
      @volume.find("x"*10).should == nil
    end

    it "should insert some data" do
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
  
  
  
end