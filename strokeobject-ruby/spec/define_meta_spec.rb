require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Empty define_meta" do
  
  before(:each) do
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = define_meta(:SomeName)
  end
  
  it "should create new module and bind it to name passed" do
    @meta.should be_a_kind_of(Module)
    SomeName.should == @meta
  end
  
end

describe "define_meta with block specified" do
  
  it "should evalutate block" do
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = define_meta(:SomeName) { def result_of_evaluation ; end  } 
    o = Object.new ; o.extend(@meta)
    o.should respond_to(:result_of_evaluation)
  end
  
end