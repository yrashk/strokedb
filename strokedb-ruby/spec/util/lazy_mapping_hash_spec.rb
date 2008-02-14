require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "LazyMappingHash instance" do
  
  before(:each) do
    @lash = LazyMappingHash.new
  end
  
  it "should have class Hash" do
    @lash.class.should == Hash
  end
  
  it "should be inherited from Hash" do
    @lash.class.ancestors.first.should == Hash
  end
  
end


describe "LazyMappingHash instance with block specified" do
  
  before(:each) do
    @original = Hash[1,2,3,4,5,6]
    @decoder = proc {|k| k.is_a?(Hash) && k[:struct] || k }
    @encoder = proc {|k| {:struct => k}  }
    
    @lash = LazyMappingHash.new(@original).map_with(&@encoder).unmap_with(&@decoder)
    
  end

  it "should call mapping proc on #[key]" do
    @lash[1].should == @encoder.call(@original[1])
    @lash[2].should == @encoder.call(@original[2])
  end
  
  it "should call mapping proc on #[mapped_key]" do
    @lash[@encoder.call(1)].should == @encoder.call(@original[1])
    @lash[@encoder.call(2)].should == @encoder.call(@original[2])
  end
  
  it "should yield mapped key/value in #each block" do
    orig_kv = []
    lash_kv = []
    @original.each do |k, v|
      orig_kv << [@encoder.call(k), @encoder.call(v)]
    end
    @lash.each do |k, v|
      lash_kv << [k,v]
    end
    orig_kv.should == lash_kv
  end
  
  it "should yield mapped key/value in #map block" do
    orig_kv = @original.map do |k, v|
      [@encoder.call(k), @encoder.call(v)]
    end
    lash_kv = @lash.map do |k, v|
      [k, v]
    end
    orig_kv.should == lash_kv
  end
  
  it "should yield mapped key/value in #zip block (lash.zip(original))" do
    orig_kv = []
    lash_kv = []
    @original.zip(@original) do |kv1, kv2|
      orig_kv << [kv1.map{|e| @encoder.call(e)}, kv2]
    end
    @lash.zip(@original) do |kv1, kv2|
      lash_kv << [kv1, kv2]
    end
    orig_kv.should == lash_kv
  end
    
  # TODO: zip support
  
end


