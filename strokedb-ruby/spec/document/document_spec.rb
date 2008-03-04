require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Document", :shared => true do

  it "should create new slot" do
    lambda do
      @document[:new_slot] = "someval"
      @document[:new_slot].should == "someval"
    end.should change(@document,:slotnames)
  end

  it "should be able to remove slot" do
    original_slotnames = @document.slotnames
    lambda do
      @document[:new_slot] = "someval"
      @document[:new_slot].should == "someval"
    end.should change(@document,:slotnames)
    lambda do
      @document.remove_slot!(:new_slot)
    end.should change(@document,:slotnames)
    @document.slotnames.should == original_slotnames
  end

  
  it "should call when_slot_not_found callback on missing slot" do 
    @document.callbacks['when_slot_not_found'] = [mock("callback")]
    @document.should_receive(:execute_callbacks).with(:when_slot_not_found,'slot_that_surely_does_not_exist').and_return("Yes!")
    @document.slot_that_surely_does_not_exist.should == "Yes!"
  end

  it "should raise an exception if slot not found when trying to read it" do
    lambda { @document.slot_that_never_can_exist }.should raise_error(SlotNotFoundError)
  end
  
  it "should allow to write slot by writer method" do
    @document.slot1 = 2
    @document[:slot1].should == 2
  end
  
  it "should allow to read slot by reader method" do
    @document[:slot1] = 1
    @document.slot1.should == 1
  end
  
  it "should allow to read slot by reader? method" do
    @document[:slot1] = 1
    @document[:slot2] = 0
    @document[:slot3] = nil
    @document.slot1?.should be_true
    @document.slot2?.should be_true
    @document.slot3?.should be_false
  end
  
  it "should add callbacks" do
    cb1 = Callback.new(nil,:callback_name) {}
    cb2 = Callback.new(nil,:another_callback_name) {}
    @document.add_callback(cb1)
    @document.add_callback(cb2)
    @document.callbacks[:callback_name].should include(cb1)
    @document.callbacks[:another_callback_name].should include(cb2)
  end

  it "should replace uniquely identified callbacks" do
    cb1 = Callback.new(nil,:callback_name, :special) {}
    cb2 = Callback.new(nil,:callback_name, :special) {}
    @document.add_callback(cb1)
    @document.add_callback(cb2)
    @document.callbacks[:callback_name].should have(1).item
    @document.callbacks[:callback_name].should include(cb2)
  end
  
  it "should report existing slot as existing" do
    @document[:existing_slot] = 1
    @document.should have_slot(:existing_slot)
  end

  it "should report existing slot with nil value as existing" do
    @document[:existing_slot] = nil
    @document.should have_slot(:existing_slot)
  end
  
  it "should report non-existing slot as non-existing" do
    @document.should_not have_slot(:existing_slot)
  end
  
  it "should report existing 'virtual' slot as existing" do
    @document.should_receive(:method_missing).with(:existing_slot).and_return 1
    @document.should have_slot(:existing_slot)
  end

  it "should report non-existing 'virtual' slot as non-existing" do
    @document.should_receive(:method_missing).with(:existing_slot).and_return { raise SlotNotFoundError.new(:existing_slot)}
    @document.should_not have_slot(:existing_slot)
  end
  
  it "should convert Symbol values to String instantly (including Symbol usage in structures)" do
    pending
    @document.symbol_slot = :a
    @document.symbol_slot.should == "a"
    @document.symbol_slot = [[:a]]
    @document.symbol_slot.should == [["a"]]
    @document.symbol_slot = {:a => :b}
    @document.symbol_slot.should == {"a" => "b"}
    @document.symbol_slot = [{:a => :b}]
    @document.symbol_slot.should == [{"a" => "b"}]
  end

  it "should convert Symbol values to String instantly (including Symbol usage in structures)" do
    @document.symbol_slot = :a
    @document = @document.save!.reload
    @document.symbol_slot.should == "a"
    @document.symbol_slot = [[:a]]
    @document = @document.save!.reload
    @document.symbol_slot.should == [["a"]]
    @document.symbol_slot = {:a => :b}
    @document = @document.save!.reload
    @document.symbol_slot.should == {"a" => "b"}
    @document.symbol_slot = [{:a => :b}]
    @document = @document.save!.reload
    @document.symbol_slot.should == [{"a" => "b"}]
  end
  
end

describe "New Document" do

  before(:each) do
    setup_default_store
    @document = Document.new
  end

  it "should have UUID" do
    @document.uuid.should match(UUID_RE)
  end

  it "should be new" do
    @document.should be_new
  end

  it "should not be head" do
    @document.should_not be_head
  end
  
  it "should have no version" do
    @document.__version__.should be_nil
  end

  it "should have no previous version" do
    @document.__previous_version__.should be_nil
    @document.__versions__.previous.should be_nil
  end

  it "should have no slotnames" do
    @document.slotnames.should be_empty
  end

  it "should have no versions" do
    @document.__versions__.should be_empty
  end


  it "should be reloadable to itself" do
    reloaded_doc = @document.reload
    reloaded_doc.object_id.should == @document.object_id
    reloaded_doc.should be_new
  end
  
  it_should_behave_like "Document"

end

describe "New Document with slots supplied" do

  before(:each) do
    setup_default_store
    @document = Document.new(:slot1 => "val1", :slot2 => "val2")
  end

  it "should have corresponding slotnames" do
    @document.slotnames.to_set.should == ['slot1','slot2'].to_set
  end

  it "should update slot value" do
    @document[:slot1] = "someval"
    @document[:slot1].should == "someval"
  end

  it "should be saveable" do
    @document.save!
    @document.should_not be_new
  end
  
  it_should_behave_like "Document"

end

describe "Forked documents" do
  before(:each) do
    setup_default_store
  end
  it "should have the same __previous_version__ " do
    @doc1 = Document.create!(:a => 11)
    @doc1.save!
    @first_version = @doc1.__version__.dup
    @doc1.a = 12
    @doc1.save!
    
    # clone
    @doc2 = @doc1.__versions__[@first_version]
    @doc2.a = 21
    @doc2.save!
    
    @doc1.__previous_version__.should == @first_version     
    @doc2.__previous_version__.should == @first_version 
  end
end

describe "Saved Document" do

  before(:each) do
    setup_default_store
    @document = Document.create!(:some_data => 1)
  end
  
  it "should have version" do
    @document.__version__.should match(/#{VERSION_RE}/)
  end
  
  it "should not be new" do
    @document.should_not be_new
  end

  it "should be head" do
    @document.should be_head
  end
  
  it "should be reloadable" do
    reloaded_doc = @document.reload
    reloaded_doc.should == @document
    reloaded_doc.object_id.should_not == @document.object_id
  end
  
  it_should_behave_like "Document"
  
end

describe "Head Document with references" do

  before(:each) do
    setup_default_store
    @doc1 = Document.create!(:one => 1)
    @doc2 = Document.create!(:two => 2)
    @doc3 = Document.new(:three => 3)
    @document = Document.create!(:some_link => @doc1, :some_indirect_link => [@doc2], :some_other_link => @doc3)
    @document.test = :yes
    @document.save!
    @doc3.save!
  end

  it "should not link to specific versions" do
    @document.should be_head
    @document.some_link.should_not be_a_kind_of(VersionedDocument)
    @document.some_other_link.should_not be_a_kind_of(VersionedDocument)
    @document.some_indirect_link.first.should_not be_a_kind_of(VersionedDocument)
  end

  it "should not link to specific versions when reloaded" do
    @document = @document.reload
    @document.should be_head
    @document.some_link.should_not be_a_kind_of(VersionedDocument)
    @document.some_other_link.should_not be_a_kind_of(VersionedDocument)
    @document.some_indirect_link.first.should_not be_a_kind_of(VersionedDocument)
  end


end

describe "Saved VersionedDocument" do

  before(:each) do
    setup_default_store
    @document = Document.create!(:some_data => 1)
    @versioned_document = @document.__versions__[@document.__version__]
  end
  
  it "should not be head" do
    @versioned_document.should_not be_head
  end
  
  it "should be reloadable" do
    StrokeDB.default_store.should_receive(:find).with(@document.uuid,@document.__version__)
    @versioned_document.reload
  end
  
end


describe "VersionedDocument with references" do

  before(:each) do
    setup_default_store
    @doc1 = Document.create!(:one => 1)
    @doc2 = Document.create!(:two => 2)
    @doc3 = Document.new(:three => 3)
    @document = Document.create!(:some_link => @doc1, :some_indirect_link => [@doc2], :some_other_link => @doc3)
    @doc3.save!
    @versioned_document = @document.__versions__[@document.__version__]
    @versioned_document.should be_a_kind_of(VersionedDocument)
    @versioned_document.should_not be_head
  end

  it "should link to specific versions" do
    @versioned_document.some_link.should be_a_kind_of(VersionedDocument)
    @versioned_document.some_other_link.should be_a_kind_of(VersionedDocument)
    @versioned_document.some_indirect_link.first.should be_a_kind_of(VersionedDocument)
  end

end


describe "Document with previous version" do

  before(:each) do
    @store = setup_default_store
    @document = Document.create!
    @document.new_slot = 1
    @document.save!
  end

  it "should have versions" do
    @document.__version__.should_not be_empty
  end


  it "should be able to access previous version" do
    prev_version = @store.find(@document.uuid,@document.__previous_version__)
    @document.__versions__[@document.__previous_version__].should == prev_version
    @document.__versions__.previous.should == prev_version
  end

end



describe "Document with single meta" do

  before(:each) do
    @store = setup_default_store
    @meta = Document.new(@store)
    @store.should_receive(:find).with(@meta.uuid).any_number_of_times.and_return(@meta)
    
    @document = Document.new(@store, :__meta__ => @meta)
    @store.should_receive(:exists?).with(@document.uuid).any_number_of_times.and_return(false)
  end

  it "should return single meta" do
    @document.meta.should == @meta
  end

end 



describe "Document with multiple metas" do

  before(:each) do
    @store = setup_default_store
    setup_index
    @metas = []
    3.times do |i|
      @metas << Document.create!(:a => i, i => i, :name => i.to_s)
    end
    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new do
      on_initialization do |doc|
        doc.hello = 'world'
      end
    end
    
    @document = Document.new(:__meta__ => @metas)
  end

  it "should return single merged meta" do
    meta = @document.meta
    meta.should be_a_kind_of(Document)
    meta[:a].should == 2
    meta[0].should == 0
    meta[1].should == 1
    meta[2].should == 2
    meta.name.should == "0,1,2"
    @document[:__meta__].should be_a_kind_of(Array)
  end
  
  it "should be able to return metas collection" do
    @document.metas.should be_a_kind_of(Array)
  end

  it "should be able add meta by pushing its document to metas" do
    @document.metas << SomeMeta.document
    @document.hello.should == 'world'
    @document.metas.should include(SomeMeta.document)
  end

  it "should be able add meta by pushing its module to metas" do
    @document.metas << SomeMeta
    @document.hello.should == 'world'
    @document.metas.should include(SomeMeta.document)
  end

end 


describe "Document initialization with store omitted", :shared => true do

  it "should raise an exception if no default store available" do
    StrokeDB.stub!(:default_store).and_return(nil)
    lambda { Document.new(*@args) }.should raise_error(NoDefaultStoreError)
  end

  it "should use default store if available" do
    StrokeDB.stub!(:default_store).and_return(mock("Store"))
    doc = Document.new(*@args)
    doc.store.should == StrokeDB.default_store
  end

end

describe "Document initialization with store omitted but with some slots specified" do

  before(:each) do
    @args = [{:slot1 => 1}]
  end
  
  it_should_behave_like "Document initialization with store omitted"

end

describe "Document initialization with store omitted but with no slots specified" do

  before(:each) do
    @args = []
  end
  
  it_should_behave_like "Document initialization with store omitted"

end

describe "Document with version" do
  
  before(:each) do
    setup_default_store
    @document = Document.new(:some_data => 1)
  end
  
  it "should be equal to another document with the same version and uuid" do
    @another_document = Document.new(:some_data => 1)
    @another_document.stub!(:uuid).and_return(@document.uuid)
    @document.should == @another_document
  end

  it "should not be equal to another document with the same version but another uuid" do
    @another_document = Document.new(:some_data => 1)
    @document.should_not == @another_document
  end
  
end

describe "Valid Document's JSON" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_raw.to_json
    @decoded_json = ActiveSupport::JSON.decode(@json)
  end

  it "should be loadable into Document" do
    doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
    doc.uuid.should == '7bb032d4-0a3c-43fa-b1c1-eea6a980452d'
    doc.slotnames.to_set.should == ['slot1','slot2'].to_set
  end

  it "should cache its version as previous version" do
    doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
    doc.instance_variable_get(:@__previous_version__).should == @document.__version__
  end

  it "should reuse cached previous version at first modification" do
    doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
    doc[:hello] = 'world'
    doc[:hello] = 'world!'
    doc[:__previous_version__].should == @document.__version__
  end

  it "should reuse cached previous version at save without any modification" do
    doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
    @store.should_receive(:save!).with(doc)
    doc.save!
    doc[:__previous_version__].should == @document.__version__
  end


end

describe "Valid Document's JSON with meta name specified" do

  before(:each) do
    @store = setup_default_store
    @meta = Document.create!(:name => 'SomeDocument')
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2", :__meta__ => @meta)
    @json = @document.to_raw.to_json
    @decoded_json = ActiveSupport::JSON.decode(@json)
  end

  it "should load meta's module if it is available" do
    Object.send!(:remove_const,'SomeDocument') if defined?(SomeDocument)
    SomeDocument = Module.new

    doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
    doc.should be_a_kind_of(SomeDocument)
  end

  it "should not load meta's module if it is not available" do
    Object.send!(:remove_const,'SomeDocument') if defined?(SomeDocument)
    
    lambda do
      doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
    end.should_not raise_error
  end


end

describe "Valid Document's JSON with multiple meta names specified" do

  before(:each) do
    @store = setup_default_store
    @metas = []
    3.times do |i|
      @metas << Document.create!(@store, :name => "SomeDocument#{i}")
    end
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2", :__meta__ => @metas)
    @json = @document.to_raw.to_json
    @decoded_json = ActiveSupport::JSON.decode(@json)
  end

  it "should load all available meta modules" do
    Object.send!(:remove_const,'SomeDocument0') if defined?(SomeDocument0)
    SomeDocument0 = Meta.new
    Object.send!(:remove_const,'SomeDocument2') if defined?(SomeDocument2)
    SomeDocument2 = Meta.new
    doc = Document.from_raw(@store,@document.uuid,@decoded_json)
    doc.should be_a_kind_of(SomeDocument0)
    doc.should be_a_kind_of(SomeDocument2)
  end
  
  it "should call all on_initialization callbacks for all available meta modules" do
    Object.send!(:remove_const,'SomeDocument0') if defined?(SomeDocument0)
    SomeDocument0 = Meta.new do
        on_initialization do |doc|
          Kernel.send(:callback_0_called)
        end
    end
    Object.send!(:remove_const,'SomeDocument2') if defined?(SomeDocument2)
    SomeDocument2 = Meta.new do
      on_initialization do |doc|
        Kernel.send(:callback_2_called)
      end
    end
    Kernel.should_receive(:callback_0_called)
    Kernel.should_receive(:callback_2_called)
    doc = Document.from_raw(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@decoded_json)
  end
end


