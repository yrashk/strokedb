require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "MapVolume", :shared => true do

  it "should have record size" do
    @map_volume.record_size.should == 256
  end
  
  it "should have capacity" do
    @map_volume.capacity.should == 1000
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
    positions = (1..100).map { @map_volume.insert!("A"*256) }
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
    @map_volume.write!(position,"B"*256)
    @map_volume.read(position).should == "B"*256
  end

end

describe "New MapVolume" do
  
  before(:each) do
    @path = File.dirname(__FILE__) + '/../../test/storages/map.volume'
    File.unlink(@path) if File.exists?(@path)
    @map_volume = MapVolume.new(:path => @path, :record_size => 256, :capacity => 1000)
  end
  
  after(:each) do
    @map_volume.close!
    File.unlink(@path) if File.exists?(@path)
  end
  
  it "should have all capacity available" do
    @map_volume.available_capacity.should == 1000
  end
  
  it_should_behave_like "MapVolume"
  
end

describe "Existing MapVolume" do
  
  before(:each) do
    @path = File.dirname(__FILE__) + '/../../test/storages/map.volume'
    File.unlink(@path) if File.exists?(@path)
    @map_volume = MapVolume.new(:path => @path, :record_size => 256, :capacity => 1000)
    position = @map_volume.insert!(' '*256)
    @map_volume.close!
    @map_volume = MapVolume.new(:path => @path)
  end
  
  after(:each) do
    @map_volume.close!
    File.unlink(@path) if File.exists?(@path)
  end

  it "should not have all capacity available" do
    @map_volume.available_capacity.should < 1000
  end

  it_should_behave_like "MapVolume"
  
end