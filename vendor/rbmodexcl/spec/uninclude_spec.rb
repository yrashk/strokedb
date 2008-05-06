require File.dirname(__FILE__) + '/../rbmodexcl'

describe Class, "with module included" do

  before(:each) do
    $module = Module.new do
      def modded? ; true ; end
    end
    @klass = Class.new do
      include $module
    end
    @klass.new.should be_a_kind_of($module)
  end

  it "should be able to uninclude module with #uninclude" do
    @klass.uninclude($module)
    @klass.new.should_not be_a_kind_of($module)
    @klass.new.should_not respond_to(:modded?)
  end

  it "should call Module.unincluded on #uninclude" do
    $module.should_receive(:unincluded).with(@klass)
    @klass.uninclude($module)
  end

end
