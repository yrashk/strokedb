require File.dirname(__FILE__) + '/spec_helper'

# Skiplist development plan:
# 1) Version 2 with fixed k.
# 2) Version 3 with fixed k.
# 3) Version 3 with dynamic k.
# 4) Version 3 with dynamic k and chunking.

describe KDSkiplist2 do

  before(:each) do
    @kd = KDSkiplist2.new([:x, :y])
  end
  
  it "should store and retrieve multidimensional data" do
    pending
    lisbon = { :name => 'Lisbon', :x => -9, :y => 37 }
    @kd.insert(lisbon)
    @kd.find(:x => -10..0, :y => 30..40).should == [ lisbon ]
  end
  
  it "should find by specific value" do
    
  end
  
  it "should find data in a specified range" do
    
  end
  
  it "should sort data by one of the keys" do
    
  end
  
  it "should accept any object with #[] method" do
    
  end
  
end

