require File.dirname(__FILE__) + '/spec_helper'

describe "Meta meta" do
  before(:each) do
    setup_default_store
    # @mem_storage = StrokeDB::MemoryStorage.new
    # StrokeDB.stub!(:default_store).and_return(StrokeDB::Store.new(:storage => @mem_storage))
  end

  it "should have nsurl http://strokedb.com/" do
    Meta.document.nsurl.should == STROKEDB_NSURL
  end

end

describe "Meta meta instantiation with block specified" do
  
  before(:each) do
    # @mem_storage = StrokeDB::MemoryStorage.new
    # StrokeDB.stub!(:default_store).and_return(StrokeDB::Store.new(:storage => @mem_storage))
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    setup_default_store
    @meta = Meta.new(:name => "SomeName") { def result_of_evaluation ; end  } 
  end
  
  it "should evalutate block" do
    @meta.new.should respond_to(:result_of_evaluation)
  end
  
end