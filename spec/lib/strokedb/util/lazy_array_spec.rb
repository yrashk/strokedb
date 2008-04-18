require File.dirname(__FILE__) + '/spec_helper'

describe "LazyArray instance" do

  before(:each) do
    @array = LazyArray.new
  end

  it "should have class Array" do
    # Make it look like array for outer world
    @array.class.should == Array
  end

  it "should be inherited from Array" do
    @array.class.ancestors.first.should == Array
  end
end



describe "LazyArray instance with block specified" do

  before(:each) do
    @loader = proc { [1,2,3] }
    @array = LazyArray.new.load_with(&@loader)
  end

  it "should call loading proc on #[index]=" do
    @array[0]="10"
    @array.should == ["10",2,3]
  end

  it "should call loading proc on #[index]" do
    @array[0].should == 1
  end

  it "should call loading proc on #[start,length]" do
    @array[0,2].should == [1,2]
  end

  it "should call loading proc on #[range]" do
    @array[0..1].should == [1,2]
  end

  it "should call loading proc on #slice(index)" do
    @array.slice(0).should == 1
  end

  it "should call loading proc on #slice(start,length)" do
    @array.slice(0,2).should == [1,2]
  end


  it "should call loading proc on #slice(range)" do
    @array.slice(0..1).should == [1,2]
  end

  it "should call loading proc on #at(index)" do
    @array.at(0).should == 1
  end

  it "should call loading proc on #first" do
    @array.first.should == 1
  end

  it "should call loading proc on #last" do
    @array.last.should == 3
  end

  it "should yield mapped value in #each block" do
    array_yielded = []
    @array.each do |val|
      array_yielded << val
    end
    array_yielded.should == [1,2,3]
  end

  it "should call loading proc on #each" do
    i = 0
    @array.each do |e|
      e.should == [1,2,3][i]
      i+=1
    end
  end

  it "should call loading proc on #each_with_index" do
    @array.each_with_index do |e, i|
      e.should == [1,2,3][i]
    end
  end

  it "should call loading proc on #inject" do
    i = 0
    @array.inject([]) do |c, e|
      e.should == [1,2,3][i]
      i += 1
    end
  end

  it "should call loading proc on #map" do
    i = 0
    @array.map do |e|
      e.should == [1,2,3][i]
      i+=1
    end
  end

  it "should call loading proc on #zip" do
    @array.zip([1,2,3]).should == [1,2,3].zip([1,2,3])
  end

  it "should call unloading proc on #push" do
    @array.push "10"
    @array.should == [1,2,3,"10"]
  end

  it "should call unloading proc on #<<" do
    @array << "10"
    @array.should == [1,2,3,"10"]
  end

  it "should call unloading proc on #unshift" do
    @array.unshift "10"
    @array.should == ["10",1,2,3]
  end

  it "should call loading proc on #pop" do
    @array.pop.should == 3
  end

  it "should call loading proc on #shift" do
    @array.shift.should == 1
  end

  it "should call loading proc on #inspect" do
    @array.inspect
    @array.should == [1,2,3]
  end

  it "should call loading proc on #find" do
    @array.find{|v| v == 2}.should == 2
  end

  it "should call loading proc on #index" do
    @array.index(2).should == 1
  end

  it "should call loading proc on #to_a" do
    @array.to_a.should == [1,2,3]
  end

  it "should call loading proc on #==" do
    @array.should == [1,2,3]
  end

end

