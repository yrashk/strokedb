require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Empty chunk store" do

  before(:each) do
    # Mock documents, mock chunk storages.
    # But don't mock Chunk. Chunk is an essential part of skiplist technology™
    
    @uuid = '34b030ab-03a5-4d97-a08a-a7b27daf0897'
    @document = mock("Document")
    @document.stub!(:uuid).and_return @uuid
    @document.stub!(:to_raw).and_return({'stuff' => '...', '__version__' => '1234'})
    @document.stub!(:version).and_return '1234'
    @document.stub!(:uuid_version).and_return "#{@uuid}.1234"
    @document.stub!(:version=).with(anything).and_return 0
    chunk_storage = MemoryChunkStorage.new
    @store = SkiplistStore.new(chunk_storage, 4)
    
  end
  
  it "should have its own UUID" do
    @store.uuid.should match(/^#{UUID_RE}$/)
  end
  
  it "should have 0 lamport_timestamp" do
    @store.lamport_timestamp.should == LamportTimestamp.zero(@store.uuid)
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

  it "should increment lamport_timestamp when storing a document" do
    lambda do 
        Document.stub!(:from_raw).and_return(@document) 
        @store.save!(@document)
    end.should change(@store,:lamport_timestamp)
  end
  
  it "should put store_uuid and lamport_timestamp into each chunk it saves" do
    Document.stub!(:from_raw).and_return(@document) 
    @store.save!(@document)
    [@uuid].map{|uuid| @store.chunk_storage.find(uuid)}.compact.each do |chunk|
      chunk.store_uuid.should == @store.uuid
      chunk.lamport_timestamp.should_not be_nil
    end
  end
  
  it "should find a versioned document" do
    Document.stub!(:from_raw).and_return(@document) 
    @store.save!(@document)
    @store.find(@uuid,@document.version).should be_a_kind_of(VersionedDocument)
  end

  it "should not find a versioned document with version that does not exist" do
    Document.stub!(:from_raw).and_return(@document) 
    @store.save!(@document)
    @store.find(@uuid,'absolutely absurd version').should be_nil
  end
  
  it "should return nil as last_version for unexistent document (well there is no documents at all)" do
    @store.last_version(Util.random_uuid).should be_nil
  end

end


describe "Non-empty chunk store" do

  before(:each) do
    # Mock documents, mock chunk storages.
    # But don't mock Chunk. Chunk is an essential part of skiplist technology™

    @store = setup_default_store
    
    @documents = []
    10.times do |i|
      @documents << Document.create!(:stuff => i)
    end
  end
  
  it "should iterate over all stored documents" do
    iterated_documents = []
    @store.each do |doc|
      iterated_documents << doc
    end
    iterated_documents.sort_by {|doc| doc.version}.should == @documents.sort_by {|doc| doc.version}
  end

  it "should iterate over all stored documents and their versions if told so" do
    iterated_documents = []
    @store.each(:include_versions => true) do |doc|
      iterated_documents << doc
    end
    documents_with_versions = @documents.clone
    @documents.each do |doc|
      doc.all_versions.each do |v|
        documents_with_versions << doc.versions[v]
      end
    end
    iterated_documents.sort_by {|doc| doc.version}.should == documents_with_versions.sort_by {|doc| doc.version}
  end
  
  it "should iterate over all newly stored documents if told so" do
    timestamp = @store.lamport_timestamp.to_s
    @new_documents = []
    10.times do |i|
      @new_documents << Document.create!(:stuff => i)
    end
    
    iterated_documents = []
    @store.each(:after_lamport_timestamp => timestamp) do |doc|
      iterated_documents << doc
    end
    iterated_documents.sort_by {|doc| doc.version}.should == @new_documents.sort_by {|doc| doc.version}
  end
  
  it "should iterate over all newly stored versions if told so" do
    timestamp = @store.lamport_timestamp.to_s
    @new_documents = []
    @documents.each_with_index do |document,i|
      document.stuff = i+100
      @new_documents << document.save!
    end
    
    iterated_documents = []
    @store.each(:after_lamport_timestamp => timestamp, :include_versions => true) do |doc|
      iterated_documents << doc
    end
    iterated_documents.sort_by {|doc| doc.version}.should == (@documents + @new_documents).sort_by {|doc| doc.version}
  end
  
  it "should be Enumerable" do
    @store.should be_a_kind_of(Enumerable)
  end

  
  

end


describe "[Regression] First chunk cut" do


  def mock_doc(uuid, s)
    document = Document.new(s,:stuff => 123)
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


