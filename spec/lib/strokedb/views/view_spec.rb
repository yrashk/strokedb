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
  
  before(:all) do
    setup_default_store
    @view = View.define(:name => "post_comments") do |view|
      def view.map(uuid, doc)
        doc['type'] =~ /comment/ ? [[[doc.parent, doc.created_at], doc]] : nil
      end
    end
    
    @article1 = Document.create! :type => "post"
    @article2 = Document.create! :type => "post"
    @article3 = Document.create! :type => "post"
    
    @comment11 = Document.create! :type => "comment11", :parent => @article1, :created_at => Time.now+1
    @comment12 = Document.create! :type => "comment12", :parent => @article1, :created_at => Time.now+2
    @comment13 = Document.create! :type => "comment13", :parent => @article1, :created_at => Time.now+3
    
    @comment21 = Document.create! :type => "comment21", :parent => @article2, :created_at => Time.now+4
    @comment22 = Document.create! :type => "comment22", :parent => @article2, :created_at => Time.now+5
    
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
    @view.find.should == [@comment11, @comment12, @comment13, @comment21, @comment22]
  end
  
  it "should find all the article's comments" do
    @view.find(:key => @article1).should == [@comment11, @comment12, @comment13]
    @view.find(:key => @article2).should == [@comment21, @comment22]
    @view.find(:key => @article3).should == [ ]
  end
  
  
end

