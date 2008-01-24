require File.dirname(__FILE__) + '/spec_helper'

describe "Diffing documents with slot added" do
  before(:each) do
    @store = mock("Store")
    @from = Document.new @store, :slot1 => 1
    @to = Document.new @store, :slot1 => 1, :slot2 => 2
    @diff = @to.diff(@from)
  end
  
  it "should list added slot" do
    @diff.slotnames.to_set.should == ['__version__','__diff_addslot_slot2__'].to_set
    @diff.added_slots.to_set.should == ['slot2'].to_set
    @diff['__diff_addslot_slot2__'].should == 2
  end
end

describe "Diffing documents with slot removed" do
  before(:each) do
    @store = mock("Store")
    @from = Document.new @store, :slot1 => 1, :slot2 => 2
    @to = Document.new @store, :slot1 => 1
    @diff = @to.diff(@from)
  end
  
  it "should list removed slot" do
    @diff.slotnames.to_set.should == ['__version__','__diff_dropslot_slot2__'].to_set
    @diff.removed_slots.to_set.should == ['slot2'].to_set
    @diff['__diff_dropslot_slot2__'].should == 2
  end
end

describe "Diffing documents with slot changed" do
  before(:each) do
    @store = mock("Store")
    @from = Document.new @store, :slot1 => 1
    @to = Document.new @store, :slot1 => 2
    @diff = @to.diff(@from)
  end
  
  it "should list updated slot" do
    @diff.slotnames.to_set.should == ['__version__','__diff_updateslot_slot1__'].to_set
    @diff.updated_slots.to_set.should == ['slot1'].to_set
    @diff['__diff_updateslot_slot1__'].should == 2
  end
end