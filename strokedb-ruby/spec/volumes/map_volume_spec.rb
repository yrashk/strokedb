require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

[MapVolume,*MapVolume.subclasses.map{|name| name.constantize}].each do |klass|
describe "#{klass}", :shared => true do

  it "should have record size" do
    @map_volume.record_size.should == 256
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
  
end

describe "New #{klass}" do
  
  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/map.volume.#{klass}"
    FileUtils.rm_rf(@path) if File.exists?(@path)
    @map_volume = klass.new(:path => @path, :record_size => 256, :capacity => 100)
  end
  
  after(:each) do
    @map_volume.close!
    FileUtils.rm_rf(@path) if File.exists?(@path)
  end
  
  it "should be empty" do
    @map_volume.should be_empty
  end
  
  it_should_behave_like "#{klass}"
  
end

describe "Existing MapVolume" do
  
  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/map.volume.#{klass.name.to_s.demodulize}"
    FileUtils.rm_rf(@path) if File.exists?(@path)
    @map_volume = klass.new(:path => @path, :record_size => 256, :capacity => 100)
    position = @map_volume.insert!(' '*256)
    @map_volume.close!
    @map_volume = klass.new(:path => @path)
  end
  
  after(:each) do
    @map_volume.close!
    FileUtils.rm_rf(@path) if File.exists?(@path)
  end

  it "should not be empty" do
    @map_volume.should_not be_empty
  end
  
  it_should_behave_like "#{klass}"
  
end

describe "Opening invalid file with #{klass} (i.e. file with invalid signature)" do

  before(:each) do
    @path = File.dirname(__FILE__) + "/../../test/storages/map.volume.#{klass.name.to_s.demodulize}"
    FileUtils.rm_rf(@path + ".invalid") if File.exists?(@path + ".invalid")
    FileUtils.mkdir_p(@path + ".invalid")
    File.open(@path + ".invalid/bitmap","w+") do |f|
      f.write "Invalid file"
    end
  end

  after(:each) do
    FileUtils.rm_rf(@path + ".invalid") if File.exists?(@path + ".invalid")
  end
  
  it "should fail with InvalidMapVolumeError exception" do
    lambda { klass.new(:path => @path + ".invalid") }.should raise_error(InvalidMapVolumeError)
  end
  
end
end