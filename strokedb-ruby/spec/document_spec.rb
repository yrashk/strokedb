require File.dirname(__FILE__) + '/spec_helper'

describe "Document" do

  before(:each) do
    @store = mock("Store")
  end
  
  it "should be able to be created instantly" do
    @store.should_receive(:save!).with(anything)
    @store.should_receive(:exists?).with(anything).any_number_of_times.and_return(false)
    @document = Document.create(@store,:slot1 => 1)
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
  
end
  

describe "Document with previous version" do
  
  before(:each) do
    @store = mock("Store")
    @document = Document.new(@store)
    @previous_version = 'eb2dee7f2758cc60823f2d1a4034d98f605c1f793db2b9a1df1394891eb4512e'
    @document.stub!(:previous_version).and_return(@previous_version)
  end
  
  it "should have no previous version" do
    @document.previous_version.should_not be_nil
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