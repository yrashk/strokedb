require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BlockVolume do
  
  before(:all) do
    FileUtils.rm_rf(File.dirname(__FILE__) + "/../../test/storages/block_volume_spec")
  end
  
  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/block_volume_spec"
    @raw_uuid = Util.random_uuid_raw
    @size     = 2
    @count    = 2
    @options = {:raw_uuid => @raw_uuid, 
                :block_size => @size, 
                :blocks_count => @count, 
                :path => @path}
  end
  
  it "should be created with given size" do 
    dv = BlockVolume.new(@options)
    fname = dv.file_path
    File.should be_exist(fname)
    File.size(fname).should == 8 + 2*@size
    File.open(fname){|f| f.read }[8..-1].should == "\x00"*(@size*2)
    dv.delete!
    File.should_not be_exist(fname)
  end
  
  it "should write some data and read it" do
    dv = BlockVolume.new(@options)
    dv.insert(0, "x")
    dv.read(0).should == "x\x00"
    dv.insert(1, "y")
    dv.read(1).should == "y\x00"
    dv.close!
  end
  
  it "should overwrite some data and read it" do
    dv = BlockVolume.new(@options)
    dv.insert(0, "x")
    dv.read(0).should == "x\x00"
    dv.insert(0, "y")
    dv.read(0).should == "y\x00"
    dv.close!
  end
  
  it "should extend volume" do
    dv = BlockVolume.new(@options)
    dv.insert(0, "x")
    dv.read(0).should == "x\x00"
    dv.insert(1, "y")
    dv.read(1).should == "y\x00"
    dv.insert(2, "z")
    dv.read(2).should == "z\x00"
    dv.read(3).should == "\x00\x00"
    dv.close!
  end
    
  it "should raise exception if file is closed" do
    dv = BlockVolume.new(@options)
    dv.close!
    
    lambda { dv.read(0)       }.should raise_error(BlockVolume::VolumeClosedException)
    lambda { dv.insert(0, "d") }.should raise_error(BlockVolume::VolumeClosedException)
  end
  
end