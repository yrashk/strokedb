require File.dirname(__FILE__) + '/spec_helper'

describe "Store", :shared => true  do

  it "should increment timestamp when storing a document" do
    @document = Document.new :stuff => '...'
    lambda do 
      @store.save!(@document)
    end.should change(@store,:timestamp)
  end

  it "should store a document" do
    @document = Document.new :stuff => '...'
    @store.save!(@document)
    (doc = @store.find(@document.uuid)).should == @document
    doc.should_not be_a_kind_of(VersionedDocument)
  end
  
  it "should store VersionedDocument" do
    @document = Document.create! :stuff => '...'
    vd = @document.versions.all.first
    FileUtils.rm_rf TEMP_STORAGES + '/skiplist_store'
    another_cfg = StrokeDB::Config.build :base_path => TEMP_STORAGES + '/skiplist_store'
    another_store = another_cfg.stores[:default]
    another_store.save!(vd)
    another_store.find(vd.uuid,vd.version).should == vd
    another_store.find(vd.uuid).should be_nil
  end

  it "should be Enumerable" do
    @store.should be_a_kind_of(Enumerable)
  end


end

describe "New store" do

  before(:each) do
    @store = setup_default_store
  end
  
  it "should have its own UUID" do
    @store.uuid.should match(/^#{UUID_RE}$/)
  end

  it "should have 0 timestamp" do
    @store.timestamp.should == LTS.zero(@store.uuid)
  end

  it "should create corresponding StoreInfo document" do
    @store.document.should be_a_kind_of(StoreInfo)
    @store.document.uuid.should == @store.uuid
  end


  it "should return nil as head_version for unexistent document (well there is no documents at all)" do
    @store.head_version(Util.random_uuid).should be_nil
  end

  it_should_behave_like "Store"

end


describe "Non-empty store" do

  before(:each) do
    @store = setup_default_store
    setup_index
    @documents = []
    10.times do |i|
      @documents << Document.create!(:stuff => i)
    end
  end


  it "should report existing document as such" do
    @store.include?(@documents.first.uuid).should == true
  end

  it "should report existing versioned document as such" do
    @store.include?(@documents.first.uuid,@documents.first.version).should == true
  end

  it "should report versioned document that does not exist as such" do
    @store.include?(@documents.first.uuid,StrokeDB::Util.random_uuid).should == false
  end

  it "should report document that does not exist as such" do
    @store.include?('ouch, there is no way such UUID could be generated').should == false
  end

  it "should find a document" do
    (doc = @store.find(@documents.first.uuid)).should == @documents.first
    doc.should_not be_a_kind_of(VersionedDocument)
  end

  it "should find a versioned document" do
    (doc = @store.find(@documents.first.uuid,@documents.first.version)).should == @documents.first
    doc.should be_a_kind_of(VersionedDocument)
  end

  it "should not find a versioned document with version that does not exist" do
    @store.find(@documents.first.uuid,StrokeDB::Util.random_uuid).should be_nil
  end


  it "should iterate over all stored documents" do
    iterated_documents = []
    @store.each do |doc|
      iterated_documents << doc
    end
    iterated_documents.sort_by {|doc| doc.uuid}.should == @documents.sort_by {|doc| doc.uuid}
  end

  it "should iterate over all stored documents and their versions if told so" do
    iterated_documents = []
    @store.each(:include_versions => true) do |doc|
      iterated_documents << doc
    end
    documents_with_versions = @documents.clone
    @documents.each do |doc|
      doc.versions.all.each do |vd|
        documents_with_versions << vd
      end
    end
    iterated_documents.sort_by {|doc| doc.uuid}.should == documents_with_versions.sort_by {|doc| doc.uuid}
  end

  it "should iterate over all newly stored documents if told so" do
    timestamp = @store.timestamp.counter
    @new_documents = []
    10.times do |i|
      @new_documents << Document.create!(:stuff => i)
    end

    iterated_documents = []
    @store.each(:after_timestamp => timestamp) do |doc|
      iterated_documents << doc
    end
    iterated_documents.sort_by {|doc| doc.uuid}.should == @new_documents.sort_by {|doc| doc.uuid}
  end

  it "should iterate over all newly stored versions if told so" do
    timestamp = @store.timestamp.counter
    @new_documents = []
    @documents.each_with_index do |document,i|
      document.stuff = i+100
      @new_documents << document.save!
    end

    iterated_documents = []
    @store.each(:after_timestamp => timestamp, :include_versions => true) do |doc|
      iterated_documents << doc
    end
    iterated_documents.sort_by {|doc| doc.uuid}.should == (@documents + @new_documents).sort_by {|doc| doc.uuid}
  end


  it_should_behave_like "Store"


end

# 
# describe "[Regression] First chunk cut" do
# 
# 
#   before(:all) do
#     @store = setup_default_store
#     @doc1 = Document.new(@store,:stuff => 123)
#     @doc2 = Document.new(@store,:stuff => 123)
#     @doc3 = Document.new(@store,:stuff => 123)
#   end
# 
#   it "should store a document with big uuid in a first chunk" do
#     $DEBUG_CHEATERS_LEVEL = 2
#     @store.save!(@doc3)
#     @store.find(@doc3.uuid).uuid.should == @doc3.uuid
#     #  end
#     #  it "should store a document with lower uuid in a first chunk" do
#     $DEBUG_CHEATERS_LEVEL = 2
#     @store.save!(@doc1)
#     @store.find(@doc1.uuid).uuid.should == @doc1.uuid
#     @store.find(@doc3.uuid).uuid.should == @doc3.uuid
#     #  end
#     #  it "should cut a chunk with a document with medium uuid" do
#     $DEBUG_CHEATERS_LEVEL = 5
#     @store.save!(@doc2)
#     @store.find(@doc1.uuid).uuid.should == @doc1.uuid
#     @store.find(@doc3.uuid).uuid.should == @doc3.uuid
#     @store.find(@doc2.uuid).uuid.should == @doc2.uuid
#   end
# 
#   after(:each) do
#     $DEBUG_CHEATERS_LEVEL = nil
#   end
# end


