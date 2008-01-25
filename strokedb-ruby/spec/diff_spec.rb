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
    @diff.added_slots[:slot2].should == 2
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
    @diff.removed_slots[:slot2].should == 2
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
    @diff.updated_slots[:slot1].should == 2
  end
  
end

describe "Diffing documents with slot changed and slot's diff strategy is specified on meta" do

  before(:each) do
    @store = mock("Store")
    Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)

    Slot1Diff = Class.new(SlotDiffStrategy)
    Slot1Diff.should_receive(:diff).with(1,2).and_return(3)
    @meta = Document.new @store, :__diff_strategy_slot1__ => 'slot_1_diff'
    
    @store.should_receive(:find).with(@meta.uuid).any_number_of_times.and_return(@meta)
    
    @from = Document.new @store, :slot1 => 1, :__meta__ => @meta
    @to = Document.new @store, :slot1 => 2, :__meta__ => @meta
    
    @diff = @to.diff(@from)
  end

  it "should diff slot value according to its strategy" do
    @diff.updated_slots[:slot1].should == 3
  end
  
end


describe "Diffing documents with slot changed and slot's diff strategy is specified on meta, but there is no such diff strategy" do

  before(:each) do
    @store = mock("Store")
    Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)

    @meta = Document.new @store, :__diff_strategy_slot1__ => 'slot_1_diff'
    
    @store.should_receive(:find).with(@meta.uuid).any_number_of_times.and_return(@meta)
    
    @from = Document.new @store, :slot1 => 1, :__meta__ => @meta
    @to = Document.new @store, :slot1 => 2, :__meta__ => @meta
    
    @diff = @to.diff(@from)
  end

  it "should not diff slot" do
    @diff.updated_slots[:slot1].should == 2
  end
  
end

describe "Diffing documents with slot changed and slot's diff strategy is specified on meta, but diff strategy is invalid" do

  before(:each) do
    @store = mock("Store")
    Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)

    Slot1Diff = Class.new

    @meta = Document.new @store, :__diff_strategy_slot1__ => 'slot_1_diff'
    
    @store.should_receive(:find).with(@meta.uuid).any_number_of_times.and_return(@meta)
    
    @from = Document.new @store, :slot1 => 1, :__meta__ => @meta
    @to = Document.new @store, :slot1 => 2, :__meta__ => @meta
    
    @diff = @to.diff(@from)
  end

  it "should not diff slot" do
    @diff.updated_slots[:slot1].should == 2
  end
  
end
