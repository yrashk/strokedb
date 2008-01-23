require File.dirname(__FILE__) + '/spec_helper'

describe "Empty chunk store" do

  before(:each) do
    @chunk_store = mock("ChunkStore")
    @skiplist_store = SkiplistStore.new(@chunk_store)
    @document = mock("Document")
    @document.stub!(:uuid).and_return '34b030ab-03a5-4d97-a08a-a7b27daf0897'
  end
  
  it "should store a document" do
    @skiplist_store.find('34b030ab-03a5-4d97-a08a-a7b27daf0897').should == nil
  end

end
