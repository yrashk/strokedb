require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Meta module" do
  
  before(:each) do
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = define_meta(:SomeName)
    @store = mock("Store")
    Stroke.default_store = @store
  end

  it "should be able to instantiate new StrokeObject" do
    obj = SomeName.new
    obj.should be_a_kind_of(StrokeObject)
    obj.should be_a_kind_of(SomeName)
  end
  
end
