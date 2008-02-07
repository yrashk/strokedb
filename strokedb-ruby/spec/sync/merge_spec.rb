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
    @original_document = Document.create!(@store, :slot1 => 1)
    @new_version = Document.from_raw(@merging_store,@original_document.uuid,@original_document.to_raw)
    @new_version[:slot1] = 2

    @store.should_receive(:save!).with(@new_version)
    @new_version.save!
  end
  
  it "should raise exception if document's previous version isn't the last version in the store and no merge strategy is specified" do
    @original_document = Document.create!(@store, :slot1 => 1)
    @new_version = Document.from_raw(@merging_store,@original_document.uuid,@original_document.to_raw)
    @original_document[:slot2] = 2
    @original_document.save!

    @new_version[:slot1] = 2
    
    lambda { @new_version.save! }.should raise_error(MergeCondition)
  end
  
  it "should use some merge strategy if document's previous version isn't the last version in the store and merge strategy is specified" do
    
    Object.send!(:remove_const,'SomeMerge') if defined?(SomeMerge)
    SomeMerge = Class.new(MergeStrategy)

    @meta = Document.create!(@store,:__merge_strategy__ => 'some_merge')
    @original_document = Document.create!(@store, :slot1 => 1, :__meta__ => @meta)
    @new_version = Document.from_raw(@merging_store,@original_document.uuid,@original_document.to_raw)
    @original_document[:slot2] = 2
    @original_document.save!

    @new_version[:slot1] = 2

    @merging_store.should_receive(:find).with(@meta.uuid).any_number_of_times.and_return(@meta)
    @merging_store.should_receive(:find).with(@original_document.uuid).any_number_of_times.and_return(@original_document)
    
    merged_doc = mock("merged doc")
    SomeMerge.should_receive(:merge!).with(@new_version,@original_document).and_return(merged_doc)
    @store.should_receive(:save!).with(merged_doc)
    @new_version.save!
  end
end

describe "SimplePatchMergeStrategy" do
  
  before(:each) do 
    @strategy = SimplePatchMergeStrategy
    @store = SkiplistStore.new(MemoryChunkStorage.new,4)
    @another_store = SkiplistStore.new(MemoryChunkStorage.new,4)
  end
  
  it "should patch new document against changes between its previous version and last version in the store" do
    @document = Document.create!(@store, :data => "abcdef")
    @new_version = Document.from_raw(@another_store,@document.uuid,@document.to_raw)
    @new_version[:a] = 1
    @new_version.save!
    @document[:additional_slot] = "ghi"
    @document.save!
    @strategy.merge!(@new_version,@document)
    @new_version.slotnames.should include('additional_slot')
    @new_version[:additional_slot].should == "ghi"
  end
  
end