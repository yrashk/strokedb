require File.dirname(__FILE__) + '/spec_helper'

describe "LazyMappingArray instance" do
  before(:each) do
    @array = LazyMappingArray.new
  end

  it "should have class Array" do
    @array.class.should == Array
  end

  it "should be inherited from Array" do
    @array.class.ancestors.first.should == Array
  end

  it "should work in case statements" do
    @array.should be_a_kind_of(Array)
  end
end

describe "LazyMappingArray instance with map/unmap specified" do
  before(:each) do
    @original = [1,2,3,[1],[2]]
    @mapper = proc {|arg| arg.to_s }
    @unmapper = proc {|arg| arg.to_i }
    @array = LazyMappingArray.new(@original).map_with(&@mapper).unmap_with(&@unmapper)
  end

  it "should call unmapping proc on #[index]=" do
    @array[0]="10"
    Array.new(@array).first.should == 10
  end

  it "should work with #[index]=(array)" do
    @array[1,0] = %w[ 1 2 3 ]
    @original[1,0] = [1,2,3]
    # TODO: huge bug inside!
    # p @array
    # p @array.to_a
    # p @original
    # p @original.map(&@mapper)
    @array.to_a.should == @original.map(&@mapper)
  end

  it "should call mapping proc on #[index]" do
    @array[0].should == @mapper.call(@original[0])
  end

  it "should call mapping proc on #[start,length]" do
    @array[0,2].to_a.should == @original[0,2].map(&@mapper)
    @array[3,2].to_a.should == @original[3,2].map(&@mapper)
  end

  it "should call mapping proc on #[range]" do
    @array[0..1].to_a.should == @original[0..1].map(&@mapper)
    @array[3..4].to_a.should == @original[3..4].map(&@mapper)
  end

  it "should call mapping proc on #slice(index)" do
    @array.slice(0).should == @mapper.call(@original.slice(0))
  end

  it "should call mapping proc on #slice(start,length)" do
    @array.slice(0,2).to_a.should == @original.slice(0,2).map(&@mapper)
  end

  it "should call mapping proc on #slice(range)" do
    @array.slice(0..1).to_a.should == @original.slice(0..1).map(&@mapper)
  end

  it "should call mapping proc on #at(index)" do
    @array.at(0).should == @mapper.call(@original.at(0))
  end

  it "should call mapping proc on #first" do
    @array.first.should == @mapper.call(@original.first)
  end

  it "should call mapping proc on #last" do
    @array.last.should == @mapper.call(@original.last)
  end

  it "should yield mapped value in #each block" do
    mapped_original = []
    @original.each do |val|
      mapped_original << @mapper.call(val)
    end
    array_yielded = []
    @array.each do |val|
      array_yielded << val
    end
    array_yielded.should == mapped_original
  end

  it "should call mapping proc on #each" do
    i = 0
    @array.each do |e|
      e.should == @mapper.call(@original[i])
      i+=1
    end
  end

  it "should call mapping proc on #each_with_index" do
    @array.each_with_index do |e, i|
      e.should == @mapper.call(@original[i])
    end
  end

  it "should call mapping proc on #inject" do
    i = 0
    @array.inject([]) do |c, e|
      e.should == @mapper.call(@original[i])
      i+=1
    end
  end

  it "should call mapping proc on #map" do
    i = 0
    @array.map do |e|
      e.should == @mapper.call(@original[i])
      i+=1
    end
  end

  it "should call mapping proc on #zip" do
    @array.zip(@original){|a, o| a.should == @mapper.call(o)  }
  end

  it "should call unmapping proc on #push" do
    @array.push "10"
    Array.new(@array).last.should == 10
  end

  it "should call unmapping proc on #<<" do
    @array << "10"
    Array.new(@array).last.should == 10
  end

  it "should call unmapping proc on #unshift" do
    @array.unshift "10"
    Array.new(@array).first.should == 10
  end

  it "should call mapping proc on #pop" do
    @array << "10"
    @array.pop.should == "10"
  end

  it "should call mapping proc on #shift" do
    @array[0] = "10"
    @array.shift.should == "10"
  end

  it "should call mapping proc on #index" do
    @array.index(1).should == 0
  end
  
  it "should call unmapping proc on #-" do
    @array << "20"
    @array << "10"
    @array = @array - ["10"]
    Array.new(@array).last.should == 20
  end
  
  it "should call unmapping proc on #include?" do
    @array.should include("1")
    @array.should_not include("10")
  end

  it "should be == to similar non-lazy array" do
    @array.should == @original.map{|v| @mapper.call(v)}
  end
  
end
