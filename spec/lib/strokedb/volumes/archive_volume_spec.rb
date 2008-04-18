require File.dirname(__FILE__) + '/spec_helper'

describe ArchiveVolume, "initialization" do

  before(:all) do
    FileUtils.rm_rf TEMP_STORAGES + '/archive_volume_spec'
  end
  
  before(:each) do
    @path = TEMP_STORAGES + '/archive_volume_spec'
    @size     = 64*1024
    @options = {:size => @size, :path => @path}
  end
  
  it "should go well with raw uuid" do
    raw_uuid = Util.random_uuid_raw
    ArchiveVolume.new(@options.merge(:uuid => raw_uuid)).uuid.should == raw_uuid.to_formatted_uuid
  end

  it "should go well with formatted uuid" do
    uuid = Util.random_uuid
    ArchiveVolume.new(@options.merge(:uuid => uuid)).uuid.should == uuid
  end
  
  it "should generate new UUID if none given" do
    ArchiveVolume.new(@options).uuid.should match(/#{UUID_RE}/)
  end
  
  
end

describe ArchiveVolume do
  
  before(:all) do
    FileUtils.rm_rf TEMP_STORAGES + '/archive_volume_spec'
  end
  
  before(:each) do
    @path = TEMP_STORAGES + '/archive_volume_spec'
    @raw_uuid = Util.random_uuid_raw
    @size     = 64*1024
    @options = {:uuid => @raw_uuid, :size => @size, :path => @path}
  end

  it "should be created with given size" do 
    dv = ArchiveVolume.new(@options)
    fname = dv.file_path
    File.should be_exist(fname)
    File.size(fname).should == @size
    File.open(fname){|f| f.read }[4..-1].should == "\x00"*(@size-4)
    dv.delete!
    File.should_not be_exist(fname)
  end
  
  it "should write some data and return its position" do
    dv = ArchiveVolume.new(@options)
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
    dv = ArchiveVolume.new(@options)
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
    dv = ArchiveVolume.new(@options)
    dv.close!
    
    lambda { dv.read(4)       }.should raise_error(ArchiveVolume::VolumeClosedException)
    lambda { dv.insert("data") }.should raise_error(ArchiveVolume::VolumeClosedException)
  end
  
  it "should raise exception if capacity is exceeded" do
    dv = ArchiveVolume.new(@options)
    # Since ArchiveVolume maintains some system information like header and record size
    # record size of file size will exceed volume's capacity
    lambda { dv.insert(" "*@size) }.should raise_error(ArchiveVolume::VolumeCapacityExceeded)
  end
  
end