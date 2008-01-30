require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Meta module" do
  
  before(:each) do
    @mem_storage = StrokeDB::MemoryChunkStorage.new
    Stroke.default_store = StrokeDB::SkiplistStore.new(@mem_storage,6)
  end

  it "should be able to instantiate new StrokeObject which is also SomeName" do
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = Meta.new(:name => "SomeName") { def result_of_evaluation ; end  } 
    obj = SomeName.new
    obj.should be_a_kind_of(StrokeObject)
    obj.should be_a_kind_of(SomeName)
  end
  
end
