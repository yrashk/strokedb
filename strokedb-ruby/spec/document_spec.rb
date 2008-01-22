require File.dirname(__FILE__) + '/spec_helper'

describe "Newly created Document" do
  
  before(:each) do
    @store = mock("Store")
    @document = StrokeDB::Document.new(@store)
    @store.should_receive(:exists?).with(@document.uuid).any_number_of_times.and_return(false)
  end
  
  it "should have UUID" do
    @document.uuid.should match(StrokeDB::UUID_RE)
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
    lambda { @document.save! }.should raise_error(StrokeDB::UnversionedDocumentError)
  end

  it "should create new slot" do
    lambda do
      @document[:new_slot] = "someval"
      @document[:new_slot].should == "someval"
    end.should change(@document,:slotnames)
  end

  it "should update version each time slots are created" do
    lambda do
      @document[:slot3] = "val3"
    end.should change(@document,:version)
  end
  
  it "should have no previous version" do
    @document.previous_version.should be_nil
  end
  
end
  

describe "Newly created Document with slots supplied" do
  
  before(:each) do
    @store = mock("Store")
    @document = StrokeDB::Document.new(@store,:slot1 => "val1", :slot2 => "val2")
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
    @document = StrokeDB::Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_json
  end
  
  it "should be loadable into Document" do
    doc = StrokeDB::Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    doc.uuid.should == '7bb032d4-0a3c-43fa-b1c1-eea6a980452d'
    doc.slotnames.to_set.should == ['__version__','slot1','slot2'].to_set
  end
  
  
end

describe "Invalid Document's JSON (i.e. incorrect __version__)" do
  
  before(:each) do
    @store = mock("Store")
    @document = StrokeDB::Document.new(@store,:slot1 => "val1", :slot2 => "val2")
    @json = @document.to_json.gsub(@document.version,'incorrect version')
  end
  
  it "should be loadable into Document" do
    lambda do
      StrokeDB::Document.from_json(@store,'7bb032d4-0a3c-43fa-b1c1-eea6a980452d',@json)
    end.should raise_error(StrokeDB::VersionMismatchError)
  end
end