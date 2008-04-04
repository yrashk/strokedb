require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def setup
  setup_default_store
  setup_index
  Object.send!(:remove_const, 'Foo') if defined?(Foo)
end

describe "Document slot virtualization" do
  before :each do
    setup

    Foo = Meta.new do 
      virtualizes :virtual_slot
    end
  end

  it "should act like a slot" do
    f = Foo.new(:virtual_slot => 123)
    f.virtual_slot.should == 123
  end

  it "should retain its value after save" do
    f = Foo.new(:virtual_slot => 123)
    f.virtual_slot.should == 123
    f.save!
    f.virtual_slot.should == 123
  end

  it "should not serialize slot value" do
    f = Foo.create!(:virtual_slot => 123)

    f_copy = Foo.find(f.uuid)
    f_copy.has_slot?("virtual_slot").should_not be_true
  end
  
  it "should preserve version after saving document" do
    f = Foo.new(:virtual_slot => 123)
    lambda do
      f.save!
    end.should_not change(f,:version)
  end

  it "should preserve previous version after saving document" do
    f = Foo.new(:virtual_slot => 123)
    lambda do
      f.save!
    end.should_not change(f,:previous_version)
  end

  it "should allow to validate the virtual slot" do
    Bar = Meta.new do
      virtualizes :mylovelyslot
      validates_presence_of :mylovelyslot
    end

    b = Bar.new(:mylovelyslot => 456)
    b.should be_valid
    lambda { b.save! }.should_not raise_error(InvalidDocumentError)
  end

  it "should respect :if"
  it "should respect :unless"
  it "should respect both :if and :unless"
end


