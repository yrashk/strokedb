require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Diffing documents", :shared => true do
  it "should have from and to specified" do
    [:from,:to].each do |slotname|
      @diff[slotname].should be_a_kind_of(Document)
    end
  end

  it "should be appliable as patch" do
    from = @from.dup
    @diff.patch!(from)
    from.slotnames.should == @to.slotnames
    from.slotnames.each do |slotname|
      from[slotname].should == @to[slotname]
    end
  end
end

describe "Diffing documents with slot added" do
  before(:each) do
    @store = setup_default_store
    @from = Document.create! :slot1 => 1
    @to = Document.create! :slot1 => 1, :slot2 => 2
    @diff = @to.diff(@from)
  end

  it "should list added slot" do
    @diff.slotnames.to_set.should == ['__version__','__meta__','add_slot_slot2','from','to'].to_set
    @diff.added_slots.to_set.should == ['slot2'].to_set
    @diff['add_slot_slot2'].should == 2
    @diff.added_slots[:slot2].should == 2
  end

  it "should be able to clear added slots" do
    @diff.added_slots.clear!
    @diff.added_slots.should be_empty
  end
  
  it "should report as modified" do
    @diff.should be_different
  end

  it_should_behave_like "Diffing documents"

end

describe "Diffing documents with slot removed" do
  before(:each) do
    @store = setup_default_store
    @from = Document.create! :slot1 => 1, :slot2 => 2
    @to = Document.create! :slot1 => 1
    @diff = @to.diff(@from)
  end

  it "should list removed slot" do
    @diff.slotnames.to_set.should == ['__version__','__meta__','drop_slot_slot2','from','to'].to_set
    @diff.removed_slots.to_set.should == ['slot2'].to_set
    @diff['drop_slot_slot2'].should == 2
    @diff.removed_slots[:slot2].should == 2
  end
  
  it "should be able to clear removed slots" do
    @diff.removed_slots.clear!
    @diff.removed_slots.should be_empty
  end


  it "should report as modified" do
    @diff.should be_different
  end

  it_should_behave_like "Diffing documents"


end

describe "Diffing documents with slot changed" do
  before(:each) do
    @store = setup_default_store
    @from = Document.create! :slot1 => 1
    @to = Document.create! :slot1 => 2
    @diff = @to.diff(@from)
  end

  it "should list updated slot" do
    @diff.slotnames.to_set.should == ['__version__','__meta__','update_slot_slot1','from','to'].to_set
    @diff.updated_slots.to_set.should == ['slot1'].to_set
    @diff['update_slot_slot1'].should == 2
    @diff.updated_slots[:slot1].should == 2
  end
  
  it "should be able to clear changed slots" do
    @diff.updated_slots.clear!
    @diff.updated_slots.should be_empty
  end

  it "should report as modified" do
    @diff.should be_different
  end
  

  it_should_behave_like "Diffing documents"

end


['slot_1_diff','default_slot_diff'].each do |strategy|
  describe "Diffing documents with slot changed with slot diffing strategy" do
    before(:each) do
      @store = setup_default_store
      
      Object.send!(:remove_const,'Slot1Diff') if defined?(Slot1Diff)
      Slot1Diff = Class.new(SlotDiffStrategy)
      Slot1Diff.should_receive(:diff).with("abcdef","abcdef1").any_number_of_times.and_return("1")
      Slot1Diff.should_receive(:patch).with("abcdef","1").any_number_of_times.and_return("abcdef1")
      

      @meta = Document.create! :strategy_slot1 => strategy

      @from = Document.create! :slot1 => "abcdef", :__meta__ => @meta
      @to = Document.create! :slot1 => "abcdef1", :__meta__ => @meta

      @diff = @to.diff(@from)
    end

    it_should_behave_like "Diffing documents"

  end
end
