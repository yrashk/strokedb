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
end

describe "Chunked skiplist" do
  
  before(:each) do
    @cut_level = 4
    @list = Skiplist.new({}, nil, @cut_level)
    10.times do 
      @list.insert("K#{rand(100).to_s(16)}", "V", rand(@cut_level)) # do not cut
    end
  end

  it "" do
    
  end

end
