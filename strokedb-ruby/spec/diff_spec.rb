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

[DefaultSlotDiff].each do |strategy|
  
  describe "#{strategy.name} for String" do
    before(:each) do
      @string1 = "hello world"
      @string2 = "bye world"
    end
    
    it "should diff to an LCS structure" do
      strategy.diff(@string1, @string2).should be_a_kind_of(Array)
    end
    
    it "should patch string back" do
      strategy.patch(@string1,strategy.diff(@string1, @string2)).should == @string2
    end

  end
  
  describe "#{strategy.name} for Array" do
    before(:each) do
      @array1 = [1,2,3]
      @array2 = [1,5,3]
    end
    
    it "should diff to an LCS structure" do
      strategy.diff(@array1, @array2).should be_a_kind_of(Array)
    end
    
    it "should patch string back" do
      strategy.patch(@array1,strategy.diff(@array1, @array2)).should == @array2
    end
  end

  describe "#{strategy.name} for Hash" do
    before(:each) do
      @hash1 = { :a => 1}
      @hash2 = { :a => 1, :b => 2}
    end
    
    it "should diff to an LCS structure" do
      strategy.diff(@hash1, @hash2).should be_a_kind_of(Array)
    end
    
    it "should patch string back" do
      strategy.patch(@hash1,strategy.diff(@hash1, @hash2)).should == @hash2
    end
  end  
  
  
  describe "#{strategy.name} for document reference" do
    before(:each) do
      @ref1 = "@##{Util.random_uuid}"
      @ref2 = "@##{Util.random_uuid}"
    end
    
    it "should diff to an LCS structure" do
      strategy.diff(@ref1, @ref2).should be_a_kind_of(String)
    end
    
    it "should patch string back" do
      strategy.patch(@ref1,strategy.diff(@ref1, @ref2)).should == @ref2
    end
  end  
  
  
  
  describe "#{strategy.name} for number" do
    before(:each) do
      @num1 = 1
      @num2 = 2
    end
    
    it "should diff to an LCS structure" do
      strategy.diff(@num1, @num2).should be_a_kind_of(Numeric)
    end
    
    it "should patch string back" do
      strategy.patch(@num1,strategy.diff(@num1, @num2)).should == @num2
    end
  end
end
