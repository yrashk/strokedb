require File.dirname(__FILE__) + '/spec_helper'

describe View, "without a name" do

  before(:each) do
    setup_default_store
  end
  
  it "could not be initialized" do
    lambda do 
      @post_comments = View.define
    end.should raise_error(ArgumentError)
  end
  
end

describe View, "without #map method defined" do
  before(:each) do
    setup_default_store
    @post_comments = View.define(:name => "post_comments")
  end
  
  it "should raise exception when #map is used" do
     lambda { @post_comments.map("key","value") }.should raise_error(InvalidViewError)
  end
end

describe "'Has many comments' view" do
  
  before(:each) do
    setup_default_store
    @view = View.define(:name => "post_comments") do |view|
      def view.map(uuid, doc)
        doc['type'] == "comment" ? [[[doc.parent, doc.created_at], doc]] : nil
      end
    end
    
    @article1 = Document.create! :type => "post"
    @article2 = Document.create! :type => "post"
    @article3 = Document.create! :type => "post"
    
    @comment11 = Document.create! :type => "comment", :parent => @article1, :created_at => Time.now
    @comment12 = Document.create! :type => "comment", :parent => @article1, :created_at => Time.now
    @comment13 = Document.create! :type => "comment", :parent => @article1, :created_at => Time.now
    
    @comment21 = Document.create! :type => "comment", :parent => @article2, :created_at => Time.now
    @comment22 = Document.create! :type => "comment", :parent => @article2, :created_at => Time.now
    
    # shuffled order to ensure, items are sorted correctly afterwards
    @view.update(@article3)
    @view.update(@comment22)
    @view.update(@comment21)
    @view.update(@article2)    
    @view.update(@comment12)
    @view.update(@comment13)
    @view.update(@article1)
    @view.update(@comment11)
  end
  
  it "should find all the comments sorted by date" do
    @view.find.should == [@comment11, @comment12, @comment13, @comment21, @comment22]
  end
  
end

