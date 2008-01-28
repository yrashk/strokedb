require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Merging store" do
  
  before(:each) do
    @store = SkiplistStore.new(MemoryChunkStorage.new,4)
    @merging_store = MergingStore.new(@store)
  end
  
  it "should pass newly created documents to store as is" do
    @document = Document.new(@merging_store, :slot1 => 1)
    @store.should_receive(:save!).with(@document)
    @document.save!
  end
  
  it "should pass new version of document as is if it's previous version is a last version in the store" do
    @original_document = Document.create(@store, :slot1 => 1)
    @new_version = Document.from_raw(@merging_store,@original_document.uuid,@original_document.to_raw)
    @new_version[:slot1] = 2

    @store.should_receive(:save!).with(@new_version)
    @new_version.save!
  end
  
  it "should raise exception if document's previous version isn't the last version in the store and no merge strategy is specified (WHERE?)" do
    @original_document = Document.create(@store, :slot1 => 1)
    @new_version = Document.from_raw(@merging_store,@original_document.uuid,@original_document.to_raw)
    @original_document[:slot2] = 2
    @original_document.save!

    @new_version[:slot1] = 2
    
    lambda { @new_version.save! }.should raise_error(MergeCondition)
  end
  
end