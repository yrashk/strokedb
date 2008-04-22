require File.dirname(__FILE__) + '/spec_helper'

describe View do
  
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


