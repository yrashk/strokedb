require File.dirname(__FILE__) + '/spec_helper'

describe "RawData(data)" do
  
  before(:each) do
    setup_default_store
    @raw_data = RawData("some data")
  end
  
  it "should create document with data slot" do
    @raw_data.data.should == "some data"
  end
  
  it "should be a RawData" do
    @raw_data.should be_a_kind_of(RawData)
  end
  
  it "should not be saved" do
    @raw_data.should be_new
  end
  
end