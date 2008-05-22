require File.dirname(__FILE__) + '/spec_helper'

describe View, "without a name" do

  before(:each) do
    setup_default_store
  end
  
  it "could not be initialized" do
    lambda do 
      @post_comments = View.named()
    end.should raise_error(ArgumentError)
  end
  
end

describe View, "without #map method defined" do
  before(:each) do
    setup_default_store
  end
  
  it "should raise exception when view is created" do
    pending("not sure we need it")
    lambda { 
       View.named("post_comments_invalid")
    }.should raise_error(InvalidViewError)
  end
  
  it "should raise exception when #map is used" do
    Comment = Meta.new
    @post_comments = View.named("post_comments_invalid", :only => ["comment"])
    c = Comment.new :text => "hello"
    lambda { @post_comments.map(c.uuid, c) }.should raise_error(InvalidViewError)
  end
  
end

describe "'Has many comments' view" do
  
  before(:all) do
    setup_default_store
    @view = View.named("post_comments") do |view|
      def view.map(uuid, doc)
        doc['type'] =~ /comment/ ? [[[doc.parent, doc.created_at], doc]] : nil
      end
    end
    
    @article1 = Document.create! :type => "post"
    @article2 = Document.create! :type => "post"
    @article3 = Document.create! :type => "post"
    
    @comment11 = Document.create! :type => "comment11", :parent => @article1, :created_at => Time.now
    @comment12 = Document.create! :type => "comment12", :parent => @article1, :created_at => Time.now
    @comment13 = Document.create! :type => "comment13", :parent => @article1, :created_at => Time.now
    
    @comment21 = Document.create! :type => "comment21", :parent => @article2, :created_at => Time.now
    @comment22 = Document.create! :type => "comment22", :parent => @article2, :created_at => Time.now
  end
  
  it "should find all the comments sorted by date" do
    results = @view.find
    # since article UUID can be anything 
   (results == [@comment11, @comment12, @comment13,    @comment21, @comment22] || 
    results == [@comment21, @comment22,    @comment11, @comment12, @comment13]).should == true
  end
  
  it "should find all the article's comments" do
    @view.find(:key => @article1).should == [@comment11, @comment12, @comment13]
    @view.find(:key => @article2).should == [@comment21, @comment22]
    @view.find(:key => @article3).should == [ ]
  end

  it "should find all the article's comments (simple key API)" do
    @view.find(@article1).should == [@comment11, @comment12, @comment13]
    @view.find(@article2).should == [@comment21, @comment22]
    @view.find(@article3).should == [ ]
  end

  it "should find all the article's comments in a reverse order" do
    @view.find(:key => @article1, :reverse => true).should == [@comment13, @comment12, @comment11]
    @view.find(:key => @article2, :reverse => true).should == [@comment22, @comment21]
    @view.find(:key => @article3, :reverse => true).should == [ ]
  end

  it "should find all the article's comments in a reverse order (simple key API)" do
    @view.find(@article1, :reverse => true).should == [@comment13, @comment12, @comment11]
    @view.find(@article2, :reverse => true).should == [@comment22, @comment21]
    @view.find(@article3, :reverse => true).should == [ ]
  end
  
  it "should find all the article's comments with limit" do
    @view.find(:key => @article1, :limit => 2).should == [@comment11, @comment12]
    @view.find(:key => @article2, :limit => 2).should == [@comment21, @comment22]
    @view.find(:key => @article3, :limit => 2).should == [ ]
  end

  it "should find all the article's comments with offset and limit" do
    @view.find(:key => @article1, :offset => 1, :limit => 2).should == [@comment12, @comment13]
    @view.find(:key => @article2, :offset => 1, :limit => 2).should == [@comment22]
    @view.find(:key => @article3, :offset => 1, :limit => 2).should == [ ]
  end
end


describe View, "with :only option" do
  before(:each) do
    setup_default_store
    block = proc {|view|
      view.updated = "false"
      class << view
        def map(uuid, doc)
          self.updated.replace "true"
          nil # don't index
        end
        def updated?
          self.updated == "true"
        end
      end
    }
    module A; end
    A.send!(:remove_const, 'Article')          if defined?(A::Article)
    A.send!(:remove_const, 'SponsoredArticle') if defined?(A::SponsoredArticle)
    A.send!(:remove_const, 'Comment')          if defined?(A::Comment)
    
    module A
      Article          = Meta.new
      SponsoredArticle = Meta.new
      Comment          = Meta.new 
    end
    
    @generic   = View.named("generic", &block)
    @comments  = View.named("comments", :only => ["Comment"], &block)
    @c_and_a   = View.named("comments_and_articles", :only => ["Comment", "Article"], &block)
    @sponsored = View.named("sponsored", :only => ["SponsoredArticle"], &block) 
  end

  after(:each) do
    StrokeDB.send(:remove_const, :VIEW_CACHE) if defined?(StrokeDB::VIEW_CACHE)
    StrokeDB::VIEW_CACHE = {}
  end
  
  it "should update articles only" do
    a = (A::Article + A::SponsoredArticle).create!(:title => "This is a sponsored article")    
    @generic.should      be_updated
    @comments.should_not be_updated
    @c_and_a.should      be_updated
    @sponsored.should    be_updated
  end
  it "should update comments only" do
    c = A::Comment.create!(:text => "Hello")
    @generic.should       be_updated
    @comments.should      be_updated
    @c_and_a.should       be_updated
    @sponsored.should_not be_updated    
  end
end


describe View, "with block defined and saved" do
  
  before(:each) do
    setup_default_store
    @view = View.named("SomeView") do |view|
      def view.map(uuid, doc)
        [[doc,doc]]
      end
    end
  end
  
  it "should re-establish block when reloaded" do
    @view = @view.reload
    lambda { @view.map(1,2).should == [[1,2]]}.should_not raise_error(InvalidViewError)
  end
  
  it "should have the same storage when reloaded" do
    storage_id = @view.send(:storage).object_id
    @view = @view.reload
    @view.send(:storage).object_id.should == storage_id
  end
  
  it "should be findable with #named syntax" do
    View.named("SomeView").should == @view
  end

  it "should set block for found-again view if it is supplied" do
    @view = View.named("SomeView") do |view|
      def view.map(uuid, doc)
        [[doc,doc]]
      end
    end
    lambda { @view.map(1,2).should == [[1,2]]}.should_not raise_error(InvalidViewError)
  end
  
  it "should set block for found-again view if it is supplied even if it was not cached" do
    StrokeDB.send(:remove_const, :VIEW_CACHE) if defined?(StrokeDB::VIEW_CACHE)
    StrokeDB::VIEW_CACHE = {}
    
    @view = View.named("SomeView") do |view|
      def view.map(uuid, doc)
        [[doc,doc]]
      end
    end
    lambda { @view.map(1,2).should == [[1,2]]}.should_not raise_error(InvalidViewError)
  end
  
end


describe View, "with nsurl and block defined and saved" do
  
  before(:each) do
    setup_default_store
    @view = View.named("SomeView", :nsurl => "http://strokedb.com/") do |view|
      def view.map(uuid, doc)
        [[doc,doc]]
      end
    end
  end
  it "should be findable with #named syntax" do
    View.named("SomeView").should == @view
  end
  
end


describe "View#traverse_key " do
  
  before(:each) do
    setup_default_store
    @v = View.named("a") do |view|
      def view.map(*args); end
    end
  end
  
  it "should traverse misc keys" do
    @v.traverse_key("a").should      == [["a"], ["a"]]
    @v.traverse_key("z".."a").should == [["z"], ["a"]]
    @v.traverse_key([:pfx, "z".."a"]).should == [[:pfx, "z"], [:pfx, "a"]]
    @v.traverse_key([:pfx, "z".."a", :sfx]).should == [[:pfx, "z", :sfx], [:pfx, "a", :sfx]]
    @v.traverse_key([:pfx, "z".."a", 1..3]).should == [[:pfx, "z", 1], [:pfx, "a", 3]]
  end
  
  it "should traverse half-opened ranges correctly" do
    @v.traverse_key(1..Infinity).should == [[1], []]
    @v.traverse_key("z"..InfiniteString).should == [["z"], []]
    t = Time.now
    @v.traverse_key([:pfx, t..InfiniteTime]).should == [[:pfx, t], [:pfx]]
  end
  
end



