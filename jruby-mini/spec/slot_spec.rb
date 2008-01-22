require File.dirname(__FILE__) + '/spec_helper'

describe "Slot" do
  before(:each) do
    @store = mock("Store")
    @document = StrokeDB::Document.new(@store)
    @slot = StrokeDB::Slot.new(@document)
  end
  
  it "should store arbitrary value" do
    @slot.value = "some value"
    @slot.value.should == "some value"
  end
  
  it "should store Document reference if value is a new Document" do
    some_doc = StrokeDB::Document.new(mock("Store"))
    @store.should_receive(:find).with(some_doc.uuid).and_return(nil)
    @slot.value = some_doc
    @slot.value.should == some_doc
    @slot.plain_value.should match(/@##{StrokeDB::UUID_RE}/)
  end

  it "should store Document reference if value is a saved Document" do
    some_doc = StrokeDB::Document.new(mock("Store"))
    @store.should_receive(:find).with(some_doc.uuid).and_return(some_doc)
    @slot.value = some_doc
    @slot.value.should == some_doc
    @slot.plain_value.should match(/@##{StrokeDB::UUID_RE}/)
    
  end
  
end