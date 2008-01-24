require File.dirname(__FILE__) + '/spec_helper'

describe "Empty chunk store" do

  before(:each) do
    # Mock documents, mock chunk storages.
    # But don't mock Chunk. Chunk is an essential part of skiplist technology™
    
    @uuid = '34b030ab-03a5-4d97-a08a-a7b27daf0897'
    @document = mock("Document")
    @document.stub!(:uuid).and_return @uuid
    @document.stub!(:to_raw).and_return({:stuff => '...'})
    @document.stub!(:version).and_return '1234'
    Document.stub!(:from_raw).and_return(@document) 

    chunk_storage = mock("ChunkStorage")
    def chunk_storage.save!(chunk)
      @chunks ||= []
      @chunks << chunk
    end
    def chunk_storage.each(&block)
      (@chunks || []).each &block
    end
    
    @skiplist_store = SkiplistStore.new(chunk_storage, 4)
  end
  
  it "should contain no documents" do
    @skiplist_store.find(@uuid).should be_nil
    @skiplist_store.exists?(@uuid).should be_false
  end
  
  it "should store a document" do
    @skiplist_store.save!(@document)
    @skiplist_store.find(@uuid).should == @document
  end

end


