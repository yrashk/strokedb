require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

[MapVolume,MmapMapVolume].each do |klass|
describe "#{klass}", :shared => true do

  it "should have record size" do
    @map_volume.record_size.should == 256
  end
  
  it "should have capacity" do
    @map_volume.capacity.should == 100
  end
  
  it "should insert record of proper size" do
    @map_volume.insert!("A"*256)
  end

  it "should insert record of proper size and return non-negative position" do
    @map_volume.insert!("A"*256).should >= 0
  end
  
  it "should be able to read inserted record" do
    @map_volume.read(@map_volume.insert!("A"*256)).should == "A"*256
  end

  it "should return different positions for each insertion" do
    positions = (1..50).map { @map_volume.insert!("A"*256) }
    positions.uniq.should == positions
  end
  
  it "should not insert record of improper size" do
    lambda { @map_volume.insert!(" "*255) }.should raise_error(InvalidRecordSizeError)
    lambda { @map_volume.insert!(" "*257) }.should raise_error(InvalidRecordSizeError)
  end
  
  it "should decrease available capacity accordingly to insertions" do
    available_capacity = @map_volume.available_capacity
    10.times { @map_volume.insert!(" "*256) }
    @map_volume.available_capacity.should == available_capacity - 10
  end
  
  it "should increase available capacity accordingly to deletions" do
     @map_volume.insert!(" "*256)
     position = @map_volume.insert!(" "*256)
     lambda { @map_volume.delete!(position) }.should change(@map_volume,:available_capacity).by(1)
  end

  it "should insert new record into previously deleted position" do
     @map_volume.insert!(" "*256)
     position = @map_volume.insert!(" "*256)
     @map_volume.delete!(position)
     @map_volume.insert!(" "*256).should == position
  end

  it "should raise an exception if trying to read previously deleted record" do
     @map_volume.insert!(" "*256)
     position = @map_volume.insert!(" "*256)
     @map_volume.delete!(position)
     lambda { @map_volume.read(position) }.should raise_error(InvalidRecordPositionError)
  end
  
  
  it "should be able to write record at specified position" do
    position = @map_volume.insert!("A"*256)
    @map_volume.write!(position,"B"*256).should == position
    @map_volume.read(position).should == "B"*256
  end  

  it "should be able to write record at specified position if there is no record yet" do
    @map_volume.write!(0,"O"*256).should == 0
    @map_volume.available?(0).should == false
  end  
  
  it "should raise an exception when capacity is exceeded" do
    @map_volume.available_capacity.times { @map_volume.insert!("C"*256) }
    lambda { @map_volume.insert!("E"*256) }.should raise_error(MapVolumeCapacityExceeded)
  end
  

end

describe "New #{klass}" do
  
  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/map.volume.#{klass}"
    File.unlink(@path) if File.exists?(@path)
    @map_volume = klass.new(:path => @path, :record_size => 256, :capacity => 100)
  end
  
  after(:each) do
    @map_volume.close!
    File.unlink(@path) if File.exists?(@path)
  end
  
  it "should have all capacity available" do
    @map_volume.available_capacity.should == 100
  end
  
  it "should be empty" do
    @map_volume.should be_empty
  end
  
  it_should_behave_like "#{klass}"
  
end

describe "Existing MapVolume" do
  
  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/map.volume.#{klass.name.to_s.demodulize}"
    File.unlink(@path) if File.exists?(@path)
    @map_volume = klass.new(:path => @path, :record_size => 256, :capacity => 100)
    position = @map_volume.insert!(' '*256)
    @map_volume.close!
    @map_volume = klass.new(:path => @path)
  end
  
  after(:each) do
    @map_volume.close!
    File.unlink(@path) if File.exists?(@path)
  end

  it "should not have all capacity available" do
    @map_volume.available_capacity.should < 100
  end

  it "should not be empty" do
    @map_volume.should_not be_empty
  end
  
  it_should_behave_like "#{klass}"
  
end

describe "Opening invalid file with #{klass} (i.e. file with invalid signature)" do

  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/map.volume.#{klass.name.to_s.demodulize}"
    File.unlink(@path + ".invalid") if File.exists?(@path + ".invalid")
    File.open(@path + ".invalid","w+") do |f|
      f.write "Invalid file"
    end
  end

  after(:each) do
    File.unlink(@path + ".invalid") if File.exists?(@path + ".invalid")
  end
  
  it "should fail with InvalidMapVolumeError exception" do
    lambda { klass.new(:path => @path + ".invalid") }.should raise_error(InvalidMapVolumeError)
  end
  
end
end