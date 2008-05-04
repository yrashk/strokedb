require File.dirname(__FILE__) + '/../rbmodexcl'

describe Class, "extended with module" do
  
  before(:each) do
    @klass = Class.new
    @module = Module.new do
      def modded? ; true ; end
    end
    @klass.extend(@module)
    @klass.should be_a_kind_of(@module)
  end
  
  it "should be unextendable with #unextend" do
    @klass.unextend(@module)
    @klass.should_not be_a_kind_of(@module)
    @klass.should_not respond_to(:modded?)
  end
  
  it "should call Module.unextended on #unextend" do
    @module.should_receive(:unextended).with(@klass)
    @klass.unextend(@module)
  end
  
end


describe Object, "extended with module" do
  
  before(:each) do
    @object = Object.new
    @module = Module.new do
      def modded? ; true ; end
    end
    @object.extend(@module)
    @object.should be_a_kind_of(@module)
  end
  
  it "should be unextendable with #unextend" do
    @object.unextend(@module)
    @object.should_not be_a_kind_of(@module)
    @object.should_not respond_to(:modded?)
  end
  
  it "should call Module.unextended on #unextend" do
    @module.should_receive(:unextended).with(@object)
    @object.unextend(@module)
  end
  
end