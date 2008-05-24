require File.dirname(__FILE__) + '/spec_helper'

describe "Document class" do

  before(:each) do
    @store = setup_default_store
    setup_index
  end

  it "should be able to find document by UUID" do
    @document = Document.create!
    Document.find(@document.uuid).should == @document
    Document.find(@store,@document.uuid).should == @document
  end

  it "should be able to find document by query" do
    @document = Document.create!
    Document.find(:uuid => @document.uuid).should == [@document]
    Document.find(@store, :uuid => @document.uuid).should == [@document]
  end

  it "should raise ArgumentError when invoking #find with wrong argument" do
    @document = Document.create!
    [ [], nil, 1 ].each do |arg|
      lambda { Document.find(arg) }.should raise_error(ArgumentError)
    end
  end
  
end


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
    (@document.slotnames - ['previous_version']).should == original_slotnames # TODO: check this exclusion
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
    @document[:slot4] = false
    @document.slot1?.should be_true
    @document.slot2?.should be_true
    @document.slot3?.should be_false
    @document.slot4?.should be_false
  end

  # update_slots
  
  it "should batch update slots" do
    @document.update_slots(:aaa => "aaa", :bbb => true)
    @document.aaa.should == "aaa"
    @document.bbb.should == true
  end

  it "should pass batch update slots to matching slot= methods if any" do
    @document.should_receive(:aaa=).with("aaa").once
    @document.should_receive(:bbb=).with(true).once
    @document.update_slots(:aaa => "aaa", :bbb => true)
  end

  it "should batch update slots but should not touch version/previous_version if update haven't changed document" do
    @document = @document.update_slots!(:aaa => "aaa", :bbb => true).reload
    lambda do
    lambda do
      @document.update_slots(:aaa => "aaa", :bbb => true)
    end.should_not change(@document, :version)
    end.should_not change(@document, :previous_version)
  end

  it "should not save batch update slots" do
    @document.save! # ensure it is not new
    doc = @document.reload
    @document.update_slots(:aaa1 => "aaa", :bbb1 => true)
    doc = @document.reload
    doc[:aaa1].should be_nil
    doc[:bbb1].should be_nil
  end

  it "should support batch update slots with saving" do
    doc = @document.update_slots!(:aaa => "aaa", :bbb => true)
    doc.aaa.should == "aaa"
    doc.bbb.should == true
    doc = doc.reload
    doc.aaa.should == "aaa"
    doc.bbb.should == true
  end
  
  # reverse_update_slots
  
  it "should batch update slots in reverse (||=)" do
    @document.aaa = "before"
    @document.reverse_update_slots(:aaa => "after", :bbb => false)
    @document.aaa.should == "before"
    @document.bbb.should == false
  end
  
  it "should support batch reverse_update_slots with saving" do
    @document.aaa = "before"
    doc = @document.reverse_update_slots!(:aaa => "after", :bbb => false)
    doc.aaa.should == "before"
    doc.bbb.should == false
    doc = doc.reload
    doc.aaa.should == "before"
    doc.bbb.should == false
  end
    
  # callbacks

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
    @document.symbol_slot = :a
    @document.symbol_slot.should == "a"
    @document.symbol_slot = [[:a]]
    @document.symbol_slot.should == [["a"]]
    @document.symbol_slot = {:a => :b}
    @document.symbol_slot.should == {"a" => "b"}
    @document.symbol_slot = [{:a => :b}]
    @document.symbol_slot.should == [{"a" => "b"}]
  end

  it "should convert Symbol values to String (including Symbol usage in structures)" do
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

  it "should convert Meta values to Documents instantly" do
    @document.meta_slot = Meta
    @document.meta_slot.should == Meta.document(@document.store)
    @document.metas_slot = [Meta]
    @document.metas_slot.should == [Meta.document(@document.store)]
  end

  it "should convert Meta values to Documents" do
    @document.meta_slot = Meta
    @document.metas_slot = [Meta]
    @document = @document.save!.reload
    @document.meta_slot.should == Meta.document(@document.store)
    @document.metas_slot.should == [Meta.document(@document.store)]
  end

  it "should not save itself once declared immutable" do
    @document.make_immutable!
    @document.store.should_not_receive(:save!)
    @document.save!
  end

  it "should be able to return current version" do
    @document.should_not be_a_kind_of(VersionedDocument)
    @document.versions.current.should == @document
    @document.versions.current.should be_a_kind_of(VersionedDocument)
  end
  
  it "should have #hash calculated from uuid" do
    hash = @document.hash 
    another_doc = Document.from_raw(@document.store,@document.to_raw)
    another_doc_with_different_uuid = Document.from_raw(@document.store,@document.to_raw.merge('uuid' => Util.random_uuid))
    another_doc.hash.should == hash
    another_doc_with_different_uuid.hash.should_not == hash
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

  it "should have version" do
    @document.version.should_not be_nil
  end

  it "should have NIL UUID version" do
    @document.version.should == NIL_UUID
  end

  it "should have no previous version" do
    @document.previous_version.should be_nil
    @document.versions.previous.should be_nil
  end

  it "should have only version slotname" do
    @document.slotnames.to_set.should == ['version','uuid'].to_set
  end

  it "should have no versions" do
    @document.versions.should be_empty
  end


  it "should be reloadable to itself" do
    reloaded_doc = @document.reload
    reloaded_doc.object_id.should == @document.object_id
    reloaded_doc.should be_new
  end

  it "should be both first and head version" do
    @document.versions.first.should == @document
    @document.versions.head.should == @document
  end
  
  it "should return string with Document's JSON representation" do
    @document.to_json.should == "{\"uuid\":\"#{@document.uuid}\",\"version\":\"#{@document.version}\"}"
  end
  
  it "should return string with Document's XML representation" do
    pending('bug') do
      @document.to_xml.should == "FIXME"
    end
  end
  
  it_should_behave_like "Document"

end

describe "New Document with slots supplied" do

  before(:each) do
    setup_default_store
    @document = Document.new(:slot1 => "val1", :slot2 => "val2")
  end

  it "should have corresponding slotnames" do
    @document.slotnames.to_set.should == ['slot1','slot2','version','uuid'].to_set
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
  
  describe "with #slot= method(s)" do
    it "should pass matching slots to methods" do
      Kernel.should_receive(:called_slot1=).with("val1")
      my_document_class = Class.new(Document) do
        def slot1=(v)
          Kernel.send(:called_slot1=,v)
        end
      end
      @document = my_document_class.new(:slot1 => "val1", :slot2 => "val2")
      
    end
  end

end

describe "Forked documents" do
  before(:each) do
    setup_default_store
  end
  it "should have the same previous_version " do
    @doc1 = Document.create!(:a => 11)
    @doc1.save!
    @first_version = @doc1.version.dup
    @doc1.a = 12
    @doc1.save!

    # clone
    @doc2 = @doc1.versions[@first_version]
    @doc2.a = 21
    @doc2.save!

    @doc1.previous_version.should == @first_version
    @doc2.previous_version.should == @first_version
  end
end

describe "Saved Document" do

  before(:each) do
    @store = setup_default_store
    @document = Document.create!(:some_data => 1)
  end

  it "should have version" do
    @document.version.should match(/#{VERSION_RE}/)
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

  it "should not change version and previous_version once not modified and saved" do
    old_version = @document.version
    old_previos_version = @document.previous_version
    @document.save!
    @document.version.should == old_version
    @document.previous_version.should == old_previos_version
  end

  it "should change version once modified; previous version should be set to original version" do
    old_version = @document.version
    @document[:a] = 1
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
  end

  it "should not change version once Array slot is accessed" do
    @document[:a] = [1]
    @document.save!
    old_version = @document.version
    @document[:a].index(0)
    @document.version.should == old_version
  end

  it "should change version once Array slot is modified; previous version should be set to original version" do
    @document[:a] = []
    @document.save!
    old_version = @document.version
    @document = @document.reload
    @document[:a] << 1
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
    @document = @document.reload
    @document[:a].unshift 1
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
    @document = @document.reload
    @document[:a][0] = 1
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
  end

  it "should not change version once Hash slot is accessed" do
    @document[:a] = {}
    @document.save!
    old_version = @document.version
    val = @document[:a][:b]
    @document.version.should == old_version
  end

  it "should change version once Hash slot is modified; previous version should be set to original version" do
    @document[:a] = {}
    @document.save!
    old_version = @document.version
    @document[:a][:b] = 1
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
  end

  it "should change version once some slot is removed; previous version should be set to original version" do
    old_version = @document.version
    @document.remove_slot!(:some_data)
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
  end
  
  it "should be deleteable" do
    old_version = @document.version
    @document.delete!
    @document.should be_a_kind_of(DeletedDocument)
    @document.should_not be_mutable
    @document.version.should_not == old_version
    @document.previous_version.should == old_version
  end

  it_should_behave_like "Document"

end

describe "Deleted document" do
  
  before(:each) do
    @store = setup_default_store
    @document = Document.create!(:some_data => 1)
    @old_version = @document.version
    @document.delete!
  end

  it "once reloaded shouldn't be mutable" do
    @document = @document.reload
    @document.should_not be_mutable
  end
  
  it "should be undeletable" do
    undeleted_document = @document.undelete!
    @document.should_not be_mutable
    undeleted_document.should_not be_a_kind_of(DeletedDocument)
  end
  

  it "should have old version after undeletion" do
    @document = @document.undelete!
    @document.version.should == @old_version
  end
  
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

describe "Head Document with meta" do

  before(:each) do
    setup_default_store
    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new
    @document = SomeMeta.create!
    @document = @document.reload
    @document.should be_head
  end

  it "should link to head meta" do
    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new(:some_slot => 1)
    SomeMeta.document # ensure new metadoc version is saved
    @document.meta.should be_head
    @document.meta.should_not be_a_kind_of(VersionedDocument)
    @document.meta.some_slot.should == 1
  end
  
end

describe "Non-head Document with meta" do

  before(:each) do
    setup_default_store
    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new
    @document = SomeMeta.create!
    @document.update_slots! :updated => true
    @document = @document.versions.previous
    @document.should_not be_head
  end

  it "should link to exact meta version" do
    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new(:some_slot => 1)
    
    @document.meta.should_not be_head
    @document.meta.should be_a_kind_of(VersionedDocument)
    @document.meta.should_not have_slot(:some_slot)
  end
  
end
describe "Saved VersionedDocument" do

  before(:each) do
    setup_default_store
    @document = Document.create!(:some_data => 1)
    @versioned_document = @document.versions[@document.version]
  end

  it "should not be head" do
    @versioned_document.should_not be_head
  end

  it "should be reloadable" do
    StrokeDB.default_store.should_receive(:find).with(@document.uuid,@document.version)
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
    @versioned_document = @document.versions[@document.version]
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
    @first_version = Document.find(@document.uuid)
    @document.new_slot = 1
    @document.save!
    @second_version = Document.find(@document.uuid)
  end

  it "should have versions" do
    @document.version.should_not be_empty
  end


  it "should be able to access previous version" do
    prev_version = @store.find(@document.uuid,@document.previous_version)
    @document.versions[@document.previous_version].should == prev_version
    @document.versions.previous.should == prev_version
  end

  it "should be able to access first version" do
    @document.versions.first.should == @document.versions.previous
  end
  
  it "should return all previous versions of document" do
    @document.new_slot2 = 'foo'
    @document.save!
    @document.versions.all_preceding.length.should == 2
    @document.versions.all_preceding.class.should == Array
    @document.versions.all_preceding.should include(@first_version)
    @document.versions.all_preceding.should include(@second_version)
    @document.versions.all_preceding.should_not include(@document)
  end
  
end

describe "Non-head version of document" do
  before(:each) do
    @store = setup_default_store
    @document = Document.create!
    @document.new_slot = 1
    @document.save!
    @non_head_document = @document.versions.previous
  end

  it "should be able to access head version" do
    @non_head_document.versions.head.should == @document
  end
  
  it "should not be deletable" do
    lambda { @non_head_document.delete! }.should raise_error(DocumentDeletionError)
  end

end




describe "Document with a single meta" do

  before(:each) do
    @store = setup_default_store
    setup_default_store
    setup_index
    Object.send!(:remove_const, "SomeMeta") if defined? ::SomeMeta
    ::SomeMeta = Meta.new(@store)
    @meta = ::SomeMeta
    @document = Document.create!(@store, Meta => @meta)
  end

  it "but specified within array should return single meta which should be mutable" do
      @document = Document.create!(@store, Meta => [@meta])
      @document.meta.should == @meta.document
      @document.meta.should be_mutable
  end

  it "should return single meta which should be mutable" do
      @document.meta.should == @meta.document
      @document.meta.should be_mutable
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

    @document = Document.new(Meta => @metas)
  end

  it "should return single merged meta" do
    meta = @document.meta
    meta.should be_a_kind_of(Document)
    meta[:a].should == 2
    meta[0].should == 0
    meta[1].should == 1
    meta[2].should == 2
    meta.name.should == "0,1,2"
    @document[Meta].should be_a_kind_of(Array)
  end

  it "should make single merged meta immutable" do
    meta = @document.meta
    meta.should_not be_mutable
  end

  it "should be able to return metas collection" do
    @document.metas.should be_a_kind_of(Array)
  end

  it "should be able to add meta by pushing its document to metas" do
    @document.metas << SomeMeta.document
    @document.hello.should == 'world'
    @document.metas.should include(SomeMeta.document)
    @document.should be_a_kind_of(SomeMeta)
  end

  it "should be able to add meta by pushing its module to metas" do
    @document.metas << SomeMeta
    @document.hello.should == 'world'
    @document.metas.should include(SomeMeta.document)
    @document.should be_a_kind_of(SomeMeta)
  end
  
  it "should be able to remove meta by removing its document from metas" do
    @document.metas << SomeMeta.document
    @document.metas.delete SomeMeta.document
    @document.metas.should_not include(SomeMeta.document)
    @document.should_not be_a_kind_of(SomeMeta)
  end

  it "should be able to remove meta by removing its module from metas" do
    @document.metas << SomeMeta
    @document.metas.delete SomeMeta
    @document.metas.should_not include(SomeMeta.document)
    @document.should_not be_a_kind_of(SomeMeta)
  end
  

  it "should raise ArgumentError when pushing neither document nor module" do
    lambda { @document.metas << 1 }.should raise_error(ArgumentError)
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
    @another_document = Document.new(:some_data => 1, :uuid => @document.uuid)
    @another_document.version = @document.version
    @document.should == @another_document
    @document.should be_eql(@another_document)
  end

  it "should not be equal to another document with the same version but another uuid" do
    @another_document = Document.new(:some_data => 1)
    @another_document.version = @document.version
    @document.should_not == @another_document
  end

end

describe "Immutable Document" do

  before(:each) do
    setup_default_store
    @document = Document.new(:some_data => 1).make_immutable!
    @document.should_not be_mutable
  end
  
  it "should be able to be mutable again" do
    @document.make_mutable!
    @document.should be_mutable
  end
  
  
  
end

describe "Valid Document's JSON" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_raw.to_json
    @decoded_json = JSON.parse(@json)
  end

  it "should be loadable into Document" do
    doc = Document.from_raw(@store,@decoded_json)
    doc.uuid.should == @document.uuid
    doc.slotnames.to_set.should == ['slot1','slot2','version','uuid'].to_set
  end

  it "should reuse cached previous version at first modification" do
    doc = Document.from_raw(@store,@decoded_json)
    doc[:hello] = 'world'
    doc[:hello] = 'world!'
    doc[:previous_version].should == @document.version
  end


end

describe "Valid Document's JSON with meta name specified" do

  before(:each) do
    @store = setup_default_store
    Object.send!(:remove_const,'SomeDocument') if defined?(SomeDocument)
    SomeDocument = Meta.new
    @document = SomeDocument.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_raw.to_json
    @decoded_json = JSON.parse(@json)
  end

  it "should load meta's module if it is available" do
    doc = Document.from_raw(@store,@decoded_json)
    doc.should be_a_kind_of(SomeDocument)
  end

  it "should not load meta's module if it is not available" do
    lambda do
      doc = Document.from_raw(@store,@decoded_json)
    end.should_not raise_error
  end


end

describe "Valid Document's JSON with multiple meta names specified" do

  before(:each) do
    @store = setup_default_store
    @metas = []
    3.times do |i|
      @metas << Meta.new(:name => "SomeDocument#{i}")
    end
    @document = @metas.inject{|a,b| a+=b}.new(@store,:slot1 => "val1", :slot2 => "val2", Meta => @metas)
    @json = @document.to_raw.to_json
    @decoded_json = JSON.parse(@json)
  end

  it "should load all available meta modules" do
    Object.send!(:remove_const,'SomeDocument0') if defined?(SomeDocument0)
    SomeDocument0 = Meta.new
    Object.send!(:remove_const,'SomeDocument2') if defined?(SomeDocument2)
    SomeDocument2 = Meta.new
    doc = Document.from_raw(@store,@decoded_json)
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
    doc = Document.from_raw(@store,@decoded_json)
  end
end

describe "Composite document ( result of Document#+(document) )" do

  before(:each) do
    setup_default_store
    @document1 = Document.new :slot1 => 1, :x => 1
    @document2 = Document.new :slot1 => 2, :slot2 => 2
    @composite = @document1+@document2
  end

  it "should be a Document" do
    @composite.should be_a_kind_of(Document)
  end

  it "should have new UUID" do
    @composite.uuid.should match(UUID_RE)
    @composite.uuid.should_not == @document1.uuid
    @composite.uuid.should_not == @document2.uuid
  end

  it "should have new version" do
    @composite.version.should_not == @document1.version
    @composite.version.should_not == @document2.version
  end

  it "should update identical slots" do
    @composite.slot1.should == 2
  end

  it "should add different slots" do
    @composite.slot2.should == 2
  end

  it "should not remove missing slots" do
    @composite.x.should == 1
  end

end

describe "Saved document with validations" do
  
  before(:each) do
    Object.send!(:remove_const,'Foo') if defined?(Foo)
    setup_default_store
  end
  
  it "should be deletable with validates_presence_of" do
    Foo = Meta.new { validates_presence_of :name }
    doc = Foo.create! :name => 'foo'
    doc.delete!
  end
  
  it "should be deletable with validates_type_of" do
    Foo = Meta.new { validates_type_of :name, :as => 'String' }
    doc = Foo.create! :name => 'foo'
    doc.delete!
  end
  
  it "should be deletable with validates_uniqueness_of" do
    Foo = Meta.new { validates_uniqueness_of :name }
    doc = Foo.create! :name => 'foo'
    doc.delete!
  end
  
  it "should be deletable with validates_inclusion_of" do
    Foo = Meta.new { validates_inclusion_of :name, :in => ['foo','bar'] }
    doc = Foo.create! :name => 'foo'
    doc.delete!
  end
  
  it "should be deletable with validates_exclusion_of" do
    Foo = Meta.new { validates_exclusion_of :name, :in => ['foo','bar'] }
    doc = Foo.create! :name => 'ueep'
    doc.delete!
  end
  
  it "should be deletable with validates_numericality_of" do
    Foo = Meta.new { validates_numericality_of :number }
    doc = Foo.create! :number => '1'
    doc.delete!
  end
  
  it "should be deletable with validates_format_of" do
    Foo = Meta.new { validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
    doc = Foo.create! :email => 'foo@bar.org'
    doc.delete!
  end
  
  it "should be deletable with validates_confirmation_of" do
    Foo = Meta.new { validates_confirmation_of :password }
    doc = Foo.create! :password => "sekret", :password_confirmation => "sekret"
    doc.delete!
  end
  
  it "should be deletable with validates_acceptance_of" do
    Foo = Meta.new { validates_acceptance_of :eula, :accept => "yep" }
    doc = Foo.create! :eula => "yep"
    doc.delete!
  end
  
  it "should be deletable with validates_length_of" do
    Foo = Meta.new { validates_length_of :name, :within => 10..50 }
    doc = Foo.create! :name => "supercalifragilistico"
    doc.delete!
  end
  
  it "should be deletable with validates_associated" do
    Foo = Meta.new { has_many :bars; validates_associated :bars }
    Bar = Meta.new
    doc = Foo.create!
    doc.delete!
  end
  
end