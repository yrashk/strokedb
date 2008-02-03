require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

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



describe "[Regression] First chunk cut" do


  def mock_doc(uuid, s)
    document = s.new_doc(:stuff => 123)
    document.stub!(:uuid).and_return uuid
    document
  end

  before(:all) do
    # Mock documents, mock chunk storages.
    # But don't mock Chunk. Chunk is an essential part of skiplist technology™
    
    chunk_storage = MemoryChunkStorage.new
    @store = SkiplistStore.new(chunk_storage, 4)
    @doc1 = mock_doc("100", @store)
    @doc2 = mock_doc("200", @store)
    @doc3 = mock_doc("300", @store)
  end
  
  it "should store a document with big uuid in a first chunk" do
    $DEBUG_CHEATERS_LEVEL = 2
    @store.save!(@doc3)
    @store.find(@doc3.uuid).uuid.should == @doc3.uuid
#  end
#  it "should store a document with lower uuid in a first chunk" do
    $DEBUG_CHEATERS_LEVEL = 2
    @store.save!(@doc1)
    @store.find(@doc1.uuid).uuid.should == @doc1.uuid
    @store.find(@doc3.uuid).uuid.should == @doc3.uuid
#  end
#  it "should cut a chunk with a document with medium uuid" do
    $DEBUG_CHEATERS_LEVEL = 5
    @store.save!(@doc2)
    @store.find(@doc1.uuid).uuid.should == @doc1.uuid
    @store.find(@doc3.uuid).uuid.should == @doc3.uuid
    @store.find(@doc2.uuid).uuid.should == @doc2.uuid
  end
  
  after(:each) do
    $DEBUG_CHEATERS_LEVEL = nil
  end
end


