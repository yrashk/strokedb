require File.dirname(__FILE__) + '/spec_helper'

describe "Empty chunked skiplist" do
  before(:each) do
    @cut_level = 4
    @list = Skiplist.new({}, nil, @cut_level)
  end
  
  it "should make first node level at least == cut-level" do
    @list.head.level.should == 1
    @list.insert("k","v", @cut_level - 1)
    @list.head.level.should == @cut_level
    @list.head.forward[0].level.should == @cut_level
  end
  
  it "should allow first node be any level > cut-level" do
    @list.head.level.should == 1
    @list.insert("k","v", @cut_level + 3)
    @list.head.level.should == @cut_level + 3
    @list.head.forward[0].level.should == @cut_level + 3
  end
  
end

describe "Chunked skiplist" do
  
  before(:each) do
    @cut_level = 4
    @list = Skiplist.new({}, nil, @cut_level)
    10.times do |i|
      @list.insert("K#{i*10}", "V", rand(@cut_level)) # do not cut
    end
  end

  it "should return [self, nil] if not cut" do
    a, b = @list.insert("K42", "L", @cut_level-1)
    a.should == @list
    b.should be_nil
  end

  it "should cut by middle-entered value" do
    a, b = @list.insert("K42", "H", @cut_level)
    a.should == @list
    b.should be_a_kind_of(Skiplist)
    chunks_should_have_separate_values(b, a, "K50", "V")
    chunks_should_have_separate_values(b, a, "K60", "V")
    chunks_should_have_separate_values(a, b, "K30", "V")
    chunks_should_have_separate_values(a, b, "K40", "V")
  end

  def chunks_should_have_separate_values(a, b, a_key, a_value)
    a.find(a_key).should == a_value
    b.find(a_key).should == nil
  end
end
