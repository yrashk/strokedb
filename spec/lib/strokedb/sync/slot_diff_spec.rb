require File.dirname(__FILE__) + '/spec_helper'

describe "Diffing documents with slot changed and slot's diff strategy is specified on meta" do

  before(:each) do
    @store = setup_default_store
    Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)
    Slot1Diff = Class.new(SlotDiffStrategy)
    Slot1Diff.should_receive(:diff).with(1,2).and_return(3)

    @meta = Document.create! :diff_strategy_slot1 => 'slot_1_diff', :name => "Slot1DiffMeta"

    @from = Document.create! :slot1 => 1, Meta => @meta
    @to = Document.create! :slot1 => 2, Meta => @meta

    @diff = @to.diff(@from)
  end

  it "should diff slot value according to its strategy" do
    @diff.updated_slots['slot1'].should == 3
  end

end


describe "Diffing documents with slot changed and slot's diff strategy is specified on meta, but there is no such diff strategy" do

  before(:each) do
    @store = setup_default_store

    Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)
    @meta = Document.create! :diff_strategy_slot1 => 'slot_1_diff', :name => "Slot1DiffMeta"

    @from = Document.create! :slot1 => 1, Meta => @meta
    @to = Document.create! :slot1 => 2, Meta => @meta
    
    @diff = @to.diff(@from)
  end

  it "should not diff slot" do
    @diff.updated_slots['slot1'].should == 2
  end

end

describe "Diffing documents with slot changed and slot's diff strategy is specified on meta, but diff strategy is invalid" do

  before(:each) do
    @store = setup_default_store
    Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)

    Slot1Diff = Class.new

    @meta = Document.create! :diff_strategy_slot1 => 'slot_1_diff', :name => "Slot1DiffMeta"

    @from = Document.create! :slot1 => 1, Meta => @meta
    @to = Document.create! :slot1 => 2, Meta => @meta
    
    @diff = @to.diff(@from)
  end

  it "should not diff slot" do
    @diff.updated_slots['slot1'].should == 2
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
    
    it "should patch String back" do
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
    
    it "should patch Array back" do
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
    
    it "should patch Hash back" do
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
    
    it "should patch document reference back" do
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
    
    it "should patch number back" do
      strategy.patch(@num1,strategy.diff(@num1, @num2)).should == @num2
    end
  end
  
  describe "#{strategy.name} for different types" do
    before(:each) do
      @val1 = 1
      @val2 = "a"
    end
    
    it "should diff to target value" do
      strategy.diff(@val1, @val2).should == @val2
    end
    
    it "should patch number back" do
      strategy.patch(@val1,strategy.diff(@val1, @val2)).should == @val2
    end

  end
end
