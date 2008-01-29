require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Empty chunk store" do

  before(:each) do
    # Mock documents, mock chunk storages.
    # But don't mock Chunk. Chunk is an essential part of skiplist technology™
    
    @uuid = '34b030ab-03a5-4d97-a08a-a7b27daf0897'
    @document = mock("Document")
    @document.stub!(:uuid).and_return @uuid
    @document.stub!(:to_raw).and_return({:stuff => '...'})
    @document.stub!(:version).and_return '1234'
    @document.stub!(:uuid_version).and_return "#{@uuid}.1234"

    chunk_storage = MemoryChunkStorage.new
    @store = SkiplistStore.new(chunk_storage, 4)
    
  end
  
  it "should contain no documents" do
    Document.stub!(:from_raw).and_return(@document) 
    @store.find(@uuid).should be_nil
    @store.exists?(@uuid).should be_false
  end
  
  it "should store a document" do
    Document.stub!(:from_raw).and_return(@document) 
    @store.save!(@document)
    @store.find(@uuid).should == @document
    @store.find(@uuid).should_not be_a_kind_of(VersionedDocument)
  end
  
  it "should find a versioned document" do
    Document.stub!(:from_raw).and_return(@document) 
    @store.save!(@document)
    @store.find(@uuid,@document.version).should be_a_kind_of(VersionedDocument)
  end
  

end


