require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "StrokeObject initialization with store omitted", :shared => true do

  it "should raise an exception if no default store available" do
    Stroke.default_store = nil
    lambda { StrokeObject.new(*@args) }.should raise_error(NoDefaultStoreError)
  end

  it "should use default store if available" do
    Stroke.default_store = mock("Store")
    object = StrokeObject.new(*@args)
    object.store.should == Stroke.default_store
  end

end

describe "StrokeObject initialization with store omitted but with some slots specified" do

  before(:each) do
    @args = [{:slot1 => 1}]
  end
  
  it_should_behave_like "StrokeObject initialization with store omitted"

end

describe "StrokeObject initialization with store omitted but with no slots specified" do

  before(:each) do
    @args = []
  end
  
  it_should_behave_like "StrokeObject initialization with store omitted"

end

describe "StrokeObject", :shared => true do
  it "should allow to read slot by reader method" do
    @object.slot1.should == 1
  end

  it "should raise an exception if slot not found when trying to read it" do
    lambda { @object.slot_that_never_can_exist }.should raise_error(SlotNotFoundError)
  end

  it "should allow to write slot by writer method" do
    @object.slot1 = 2
    @object.slot1.should == 2
  end
  
end

describe "Newly created StrokeObject" do

  before(:each) do
    @store = mock("Store")
    @object = StrokeObject.new(@store,:slot1 => 1)
  end

  it_should_behave_like "StrokeObject"

end

