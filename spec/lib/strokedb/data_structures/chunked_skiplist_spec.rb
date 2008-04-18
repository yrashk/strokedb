require File.dirname(__FILE__) + '/spec_helper'

describe "Empty chunked skiplist" do
  before(:each) do
    @cut_level = 4
    @list = Skiplist.new({}, nil, @cut_level)
  end
  
  it "should make first node level first-level only" do
    @list.head.level.should == 1
    @list.insert("k","v", @cut_level + 1)
    @list.head.level.should == 1
    @list.head.forward[0].level.should == 1
  end
  
end


describe "Chunked skiplist (variants)" do
  
  before(:each) do
    @cut_level = 16
  end

  it "should be valid with ascending level order" do
    @list = Skiplist.new({}, nil, @cut_level)
    (1..10).each do |i|
      @list.insert("K#{i*10}", "V", i)
    end
    @list.should have(10).items
  end
  
  it "should be valid with descending level order" do
    @list = Skiplist.new({}, nil, @cut_level)
    (1..10).each do |i|
      @list.insert("K#{i*10}", "V", 11 - i)
    end
    @list.should have(10).items
  end
  
  it "should be valid with fixed level order" do
    @list = Skiplist.new({}, nil, @cut_level)
    (1..10).each do |i|
      @list.insert("K#{i*10}", "V", 15)
    end
    @list.should have(10).items
  end

end


describe "Insertion into skiplist" do
  
  before(:each) do
    @cut_level = 4
    @list = Skiplist.new({}, nil, @cut_level)
    @levels_list = []
    (0..9).each do |i|
      @list.insert("K#{i*10}", "V", x = rand(@cut_level-1)+1)
      @levels_list << x
    end
  end

  it "should return [self, nil] if not cut" do
    a, b = @list.insert("K42", "L", @cut_level-1)
    a.should == @list
    b.should be_nil
  end

  it "should cut list by middle-entered value" do
    a, b = @list.insert("K42", "H", @cut_level)
    a.should == @list
    b.should be_a_kind_of(Skiplist)
    (0..4).each do |i|
      chunks_should_have_separate_values(a, b, "K#{i*10}", "V")
    end
    chunks_should_have_separate_values(b, a, "K42", "H")
    (5..9).each do |i|
      chunks_should_have_separate_values(b, a, "K#{i*10}", "V")
    end
  end

  def chunks_should_have_separate_values(a, b, a_key, a_value)
    a.find(a_key).should == a_value
    b.find(a_key).should == nil
  end
end

=begin 
random chunk writings, bad test. Come back to it in ChunkStore
describe "Chunked skiplist process" do
  
  before(:all) do
    @cut_level = 4
    list = Skiplist.new({}, nil, @cut_level)
    @lists = {list => 1}
    n = ((1/Skiplist::PROBABILITY)**(@cut_level+2)).round
    srand 12345
    n.times do |i|
      a, b = @lists.keys[rand(@lists.size)].insert(rand(100_000).to_s, "V")
      @lists[a] = 1
      @lists[b] = 1 if b
    end
    @lists = @lists.keys
  end

  it "should produce several chunks after many insertions" do
    @lists.size.should > 1 
  end
    
  # TODO: move to separate description with narrow assertions
  it "should keep all the nodes except the first one on a lower level in each chunk" do
    counted_first_node = false
    @lists.each do |list|
      cut_level = list.map{|node| node.level }.max
      counted_cut = false
      puts list.to_s_levels
      puts "------"
      if cut_level < @cut_level
        #puts list
        #puts "------- #{cut_level}"
      end
      if cut_level < @cut_level && !counted_first_node
        counted_first_node = true
      else
        #cut_level.should >= @cut_level      
      end
      
      list.each do |node|
        unless counted_cut && node.level == cut_level
          counted_cut = true
        else
          if node.level >= @cut_level
            #puts list
          end
          #node.level.should < @cut_level
        end
      end
    end
  end

end
=end

