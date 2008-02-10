require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Document" do

  before(:each) do
    @store = mock("Store")
  end

  it "should be able to be created instantly" do
    @store.should_receive(:save!).with(anything)
    @store.should_receive(:exists?).with(anything).any_number_of_times.and_return(false)
    @document = Document.create!(@store,:slot1 => 1)
  end
  
end


describe "Newly created Document" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store)
    @store.should_receive(:exists?).with(@document.uuid).any_number_of_times.and_return(false)
  end

  it "should have UUID" do
    @document.uuid.should match(UUID_RE)
  end

  it "should be new" do
    @document.should be_new
  end

  it "should have no version" do
    @document.version.should be_nil
  end

  it "should have no slotnames" do
    @document.slotnames.should be_empty
  end

  it "cannot be saved" do
    lambda { @document.save! }.should raise_error(UnversionedDocumentError)
  end

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

  it "should update version each time slots are created" do
    lambda do
      @document[:slot3] = "val3"
    end.should change(@document,:version)
  end

  it "should have no previous version" do
    @document.previous_version.should be_nil
  end

  it "should have no versions" do
    @document.versions.should be_empty
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

end


describe "Document with previous version" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store)
    @previous_version = 'eb2dee7f2758cc60823f2d1a4034d98f605c1f793db2b9a1df1394891eb4512e'
    @document.stub!(:previous_version).and_return(@previous_version)
  end

  it "should have versions" do
    @document.versions.should_not be_empty
  end

  it "should be able to access previous version" do
    @document_with_previous_version = mock("Document with previous version")
    @store.should_receive(:find).with(@document.uuid,@previous_version).and_return(@document_with_previous_version)
    @document.versions[@previous_version].should == @document_with_previous_version
  end

end


describe "Newly created Document with slots supplied" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @store.should_receive(:exists?).with(@document.uuid).any_number_of_times.and_return(false)
  end

  it "should have version" do
    @document.version.should_not be_nil
  end

  it "should have corresponding slotnames, including __version__ slotname" do
    @document.slotnames.to_set.should == ['__version__','slot1','slot2'].to_set
  end

  it "should update slot value" do
    @document[:slot1] = "someval"
    @document[:slot1].should == "someval"
  end

  it "should update version each time slots are updated" do
    lambda do
      @document[:slot1] = "newval"
    end.should change(@document,:version)
  end

  it "should save itself" do
    @store.should_receive(:save!).with(@document)
    @document.save!
  end


end

describe "Document with single meta" do

  before(:each) do
    @store = mock("Store")
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
    @metas = []
    3.times do |i|
      @metas << Document.create!(:a => i, i => i)
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
    @document[:__meta__].should be_a_kind_of(Array)
  end

end 


describe "Valid Document's JSON" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_json
  end

  it "should be loadable into Document" do
    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc.uuid.should == '7bb032d4-0a3c-43fa-b1c1-eea6a980452d'
    doc.slotnames.to_set.should == ['__version__','slot1','slot2'].to_set
  end

  it "should cache its version as previous version" do
    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc.instance_variable_get(:@__previous_version__).should == @document.version
  end

  it "should reuse cached previous version at first modification" do
    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc[:hello] = 'world'
    doc[:hello] = 'world!'
    doc[:__previous_version__].should == @document.version
  end

  it "should reuse cached previous version at save without any modification" do
    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    @store.should_receive(:exists?).with('7bb032d4-0a3c-43fa-b1c1-eea6a980452d').and_return(true)
    @store.should_receive(:save!).with(doc)
    doc.save!
    doc[:__previous_version__].should == @document.version
  end


end

describe "Valid Document's JSON with meta name specified" do

  before(:each) do
    @store = mock("Store")
    @meta = Document.new(@store,:name => 'SomeDocument')
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2", :__meta__ => @meta)
    @json = @document.to_json
    @store.should_receive(:find).with(@meta.uuid).any_number_of_times.and_return(@meta)
  end

  it "should load meta's module if it is available" do
    Object.send!(:remove_const,'SomeDocument') if defined?(SomeDocument)
    SomeDocument = Module.new

    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc.should be_a_kind_of(SomeDocument)
  end

  it "should not load meta's module if it is not available" do
    Object.send!(:remove_const,'SomeDocument') if defined?(SomeDocument)
    
    lambda do
      doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    end.should_not raise_error
  end


end

describe "Valid Document's JSON with multiple meta names specified" do

  before(:each) do
    @store = mock("Store")
    @metas = []
    3.times do |i|
      @metas << Document.new(@store, :name => "SomeDocument#{i}")
      @store.should_receive(:find).with(@metas.last.uuid).any_number_of_times.and_return(@metas.last)
    end
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2", :__meta__ => @metas)
    @json = @document.to_json
  end

  it "should load all available meta modules" do
    Object.send!(:remove_const,'SomeDocument0') if defined?(SomeDocument0)
    SomeDocument0 = Meta.new
    Object.send!(:remove_const,'SomeDocument2') if defined?(SomeDocument2)
    SomeDocument2 = Meta.new
    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc.should be_a_kind_of(SomeDocument0)
    doc.should be_a_kind_of(SomeDocument2)
  end
  
  it "should call all on_initialization callbacks for all available meta modules" do
    Object.send!(:remove_const,'SomeDocument0') if defined?(SomeDocument0)
    SomeDocument0 = Meta.new do
        on_initialization do |doc|
          doc.instance_variable_set(:@callback_0_called,true)
        end
    end
    Object.send!(:remove_const,'SomeDocument2') if defined?(SomeDocument2)
    SomeDocument2 = Meta.new do
      on_initialization do |doc|
        doc.instance_variable_set(:@callback_2_called,true)
      end
    end
    doc = Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc.instance_variable_get(:@callback_0_called).should be_true
    doc.instance_variable_get(:@callback_2_called).should be_true
  end
  
  

end



describe "Invalid Document's JSON (i.e. incorrect __version__)" do

  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_json.gsub(@document.version,'incorrect version')
  end

  it "should not be loadable into Document" do
    lambda do
      Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    end.should raise_error(VersionMismatchError)
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