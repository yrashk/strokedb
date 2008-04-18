require File.dirname(__FILE__) + '/spec_helper'

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

  it "should coerce initialization slot specified to a string" do
    Foo = Meta.new do
      coerces :some_slot, :to => :string
    end
    foo = Foo.new(:some_slot => 1)
    foo.some_slot.should == "1"
  end

  it "should coerce slot specified to a string" do
    Foo = Meta.new do
      coerces :some_slot, :to => :string
    end
    foo = Foo.new
    foo.some_slot = 1
    foo.some_slot.should == "1"
  end

  it "should coerce initialization slots specified" do
    Foo = Meta.new do
      coerces [:some_slot, :another_slot], :to => :string
    end
    foo = Foo.new(:some_slot => 1, :another_slot => 2)
    foo.some_slot.should == "1"
    foo.another_slot.should == "2"
  end

  it "should coerce slots specified" do
    Foo = Meta.new do
      coerces [:some_slot, :another_slot], :to => :string
    end
    foo = Foo.new
    foo.some_slot = 1
    foo.some_slot.should == "1"
    foo.another_slot = 2
    foo.another_slot.should == "2"
  end


  it "should not coerce initialization non-numeric slot specified to a number" do
    Foo = Meta.new do
      coerces :some_slot, :to => :number
    end
    foo = Foo.new(:some_slot => "bad1")
    foo.some_slot.should == "bad1"
  end
  
  it "should respect :if" do
    Foo = Meta.new do
      coerces :some_slot, :to => :number, :if => 'if_slot'
    end
    foo = Foo.new
    foo.if_slot = true
    foo.some_slot = "1"
    foo.some_slot.should == 1
    foo = Foo.new
    foo.if_slot = false
    foo.some_slot = "1"
    foo.some_slot.should == "1"
  end

  it "should respect :unless" do
    Foo = Meta.new do
      coerces :some_slot, :to => :number, :unless => 'if_slot'
    end
    foo = Foo.new
    foo.if_slot = true
    foo.some_slot = "1"
    foo.some_slot.should == "1"
    foo = Foo.new
    foo.if_slot = false
    foo.some_slot = "1"
    foo.some_slot.should == 1
  end

end

