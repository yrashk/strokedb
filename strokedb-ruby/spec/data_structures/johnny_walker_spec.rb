require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
 
describe JohnnyWalker::Helper do


end

describe JohnnyWalker::Base do
  
  before(:all) do
    @bn = JohnnyWalker::Base.new([:x, :y, :name])
    @lisbon = { :name => 'Lisbon', :x => -9, :y => 37 }
  end

  before(:each) do
    @bn_empty = JohnnyWalker::Base.new([:x, :y, :name])
  end  

  it "should store data" do
    pending
    @bn.insert(@lisbon)
  end
  
  it "should find data by 2/3 coordinates" do
    pending
    @bn.find(:x => -9, :y => 37).should == @lisbon
  end
  

end
