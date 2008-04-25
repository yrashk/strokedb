require File.dirname(__FILE__) + '/spec_helper'

describe View, "without #map method defined" do
  before(:each) do
    setup_default_store
    @post_comments = View.find_or_create(:name => "post_comments")
  end
  
  it "should raise exception when #map is used" do
     lambda { @post_comments.map(Document.new) }.should raise_error(InvalidViewError)
  end
end

describe View, "with #map method defined" do
  
  before(:each) do
    setup_default_store
    @post_comments = View.find_or_create(:name => "post_comments") do |view|
      def view.map(doc)
        [ [doc, doc] ]
      end
    end
  end
  
  it "should have map method" do
    @post_comments.map(123).should == [ [ 123, 123 ] ] 
  end
  
  
  
end


