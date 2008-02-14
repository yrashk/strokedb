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
    @key_mapper  = proc {|k| k.is_a?(Hash) && k[:key] || k }
    @pair_mapper = proc {|k, v| [{:key => k}, "value: #{v.inspect}"] }
    @lash = LazyMappingHash.new(@original, @key_mapper, @pair_mapper) 
  end

  it "should call mapping proc on #[key]" do
    @lash[1].should == @pair_mapper.call(1, @original[1]).last
    @lash[2].should == @pair_mapper.call(2, @original[2]).last
  end
  
  it "should call mapping proc on #[mapped_key]" do
    @lash[@pair_mapper.call(1, nil).first].should == @pair_mapper.call(1, @original[1]).last
    @lash[@pair_mapper.call(2, nil).first].should == @pair_mapper.call(2, @original[2]).last
  end
  
  it "should yield mapped key/value in #each block" do
    orig_kv = []
    lash_kv = []
    @original.each do |k, v|
      orig_kv << @pair_mapper.call(k, v)
    end
    @lash.each do |k, v|
      lash_kv << [k,v]
    end
    orig_kv.should == lash_kv
  end
  
  it "should yield mapped key/value in #map block" do
    orig_kv = @original.map do |k, v|
      @pair_mapper.call(k, v)
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
      orig_kv << [@pair_mapper.call(*kv1), kv2]
    end
    @lash.zip(@original) do |kv1, kv2|
      lash_kv << [kv1, kv2]
    end
    orig_kv.should == lash_kv
  end
  
  # it "should yield mapped key/value in #zip block (lash.zip(lash))" do
  #   orig_kv = []
  #   lash_kv = []
  #   @original.zip(@original) do |kv1, kv2|
  #     orig_kv << [@pair_mapper.call(*kv1), @pair_mapper.call(*kv2)]
  #   end
  #   @lash.zip(@lash) do |kv1, kv2|
  #     lash_kv << [kv1, kv2]
  #   end
  #   orig_kv.should == lash_kv
  # end
  # 
  # it "should yield mapped key/value in #zip block (original.zip(lash))" do
  #   orig_kv = []
  #   lash_kv = []
  #   @original.zip(@original) do |kv1, kv2|
  #     orig_kv << [kv1, @pair_mapper.call(*kv2)]
  #   end
  #   @original.zip(@lash) do |kv1, kv2|
  #     lash_kv << [kv1, kv2]
  #   end
  #   orig_kv.should == lash_kv
  # end
  
=begin
  
  it "should call mapping proc on #zip" do
    @array.zip(@original){|a, o| a.should == @mapper.call(o)  }
  end 
=end 
end
