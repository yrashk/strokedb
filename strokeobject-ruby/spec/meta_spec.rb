require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Meta module" do

  before(:each) do
    setup_index
    @mem_storage = StrokeDB::MemoryChunkStorage.new
    Stroke.default_store = StrokeDB::SkiplistStore.new(@mem_storage,6, @index)
    @index.document_store = Stroke.default_store
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = Meta.new(:name => "SomeName")  
  end

  it "should be able to instantiate new StrokeObject which is also SomeName" do
    obj = SomeName.new
    obj.should be_a_kind_of(StrokeObject)
    obj.should be_a_kind_of(SomeName)
  end

  it "should have corresponding document" do
    doc = SomeName.document
    doc.should_not be_nil
    doc.should be_a_kind_of(Meta)
  end

  it "should find document instead of creating it" do
    doc = SomeName.document
    pending("there is a bug")
    10.times { SomeName.document.uuid.should == doc.uuid }
  end

  it "should save new document version if it was updated" do
    doc = SomeName.document
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = Meta.new(:name => "SomeName", :description => "Something")  
    new_doc = SomeName.document
    new_doc.uuid.should == doc.uuid
    new_doc.previous_version.should_not be_nil
    new_doc.previous_version.should == doc.version
    new_doc.description.should == "Something"
  end

  
  private
  
  def setup_index
    index_storage = StrokeDB::InvertedListFileStorage.new('test/storages/inverted_list_storage')
    index_storage.clear!
    @index = StrokeDB::InvertedListIndex.new(index_storage)
  end

end
