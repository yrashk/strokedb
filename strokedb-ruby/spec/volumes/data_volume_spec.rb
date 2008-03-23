require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DataVolume do
  
  before(:all) do
    FileUtils.rm_rf(File.dirname(__FILE__) + "/../../test/storages/data_volume_spec")
  end
  
  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/data_volume_spec"
    @raw_uuid = Util.random_uuid_raw
    @size     = 64*1024
    @options = {:raw_uuid => @raw_uuid, :size => @size, :path => @path}
  end
  
  it "should be created with given size" do 
    dv = DataVolume.new(@options)
    fname = dv.file_path
    File.should be_exist(fname)
    File.size(fname).should == @size
    File.open(fname){|f| f.read }[4..-1].should == "\x00"*(@size-4)
    dv.delete!
    File.should_not be_exist(fname)
  end
  
  it "should write some data and return its position" do
    dv = DataVolume.new(@options)
    tail = dv.tail
    tail.should == 4
    prefix = 4
    
    p1 = dv.insert("7 bytes")
    p1.should == 0 + tail
    p2 = dv.insert("13 more bytes")
    p2.should == 7 + prefix + tail
    p3 = dv.insert("1")
    p3.should == 20 + prefix*2 + tail
    dv.close!
  end
  
  it "should read & write data" do
    dv = DataVolume.new(@options)
    p1 = dv.insert("7 bytes")
    p2 = dv.insert("13 more bytes")
    p3 = dv.insert("1")
    
    dv.read(p2).should == "13 more bytes"
    dv.read(p1).should == "7 bytes"
    dv.read(p3).should == "1"
    
    p4 = dv.insert("")
    
    dv.read(p2).should == "13 more bytes"
    dv.read(p1).should == "7 bytes"
    dv.read(p3).should == "1"
    dv.read(p4).should == ""
    
    dv.close!
  end
  
  it "should raise exception if file is closed" do
    dv = DataVolume.new(@options)
    dv.close!
    
    lambda { dv.read(4)       }.should raise_error(DataVolume::VolumeClosedException)
    lambda { dv.insert("data") }.should raise_error(DataVolume::VolumeClosedException)
  end
  
end