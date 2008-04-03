require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def setup
  setup_default_store
  setup_index
  Object.send!(:remove_const, 'Foo') if defined?(Foo)
  Object.send!(:remove_const, 'Bar') if defined?(Bar)
  Object.send!(:remove_const, 'User') if defined?(User)
  Object.send!(:remove_const, 'Email') if defined?(Email)
  Object.send!(:remove_const, 'Item') if defined?(Item)
end

describe "Document slot coercion" do
  before :each do
    setup
  end
  
  it "should coerce initialization slot specified to a number" do
    Foo = Meta.new do
      coerces :some_slot, :to => :number
    end
    foo = Foo.new(:some_slot => "1")
    foo.some_slot.should == 1
  end

  it "should coerce slot specified to a number" do
    Foo = Meta.new do
      coerces :some_slot, :to => :number
    end
    foo = Foo.new
    foo.some_slot = "1"
    foo.some_slot.should == 1
  end

  it "should not coerce initialization non-numeric slot specified to a number" do
    Foo = Meta.new do
      coerces :some_slot, :to => :number
    end
    foo = Foo.new(:some_slot => "bad1")
    foo.some_slot.should == "bad1"
  end

end

