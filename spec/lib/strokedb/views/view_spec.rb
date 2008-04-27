require File.dirname(__FILE__) + '/spec_helper'

describe View, "without a name" do

  before(:each) do
    setup_default_store
  end
  
  it "could not be initialized" do
    lambda do 
      @post_comments = View.find_or_create
    end.should raise_error(ArgumentError)
  end
  
end

describe View, "without #map method defined" do
  before(:each) do
    setup_default_store
    @post_comments = View.find_or_create(:name => "post_comments")
  end
  
  it "should raise exception when #map is used" do
     lambda { @post_comments.map("key","value") }.should raise_error(InvalidViewError)
  end
end

describe View, "with #map method defined" do
  
  before(:each) do
    setup_default_store
    @post_comments = View.find_or_create(:name => "post_comments") do |view|
      def view.map(key, value)
        [ [key, value] ]
      end
    end
  end
  
  it "should have map method" do
    @post_comments.map(123,123).should == [ [ 123, 123 ] ] 
  end
  
  
  
end


