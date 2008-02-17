require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Hash diff" do
  
  before(:each) do
    @hash = {:a => 1}
    @obj = Object.new
  end
  
  it "should correctly patch hash with hash diff" do
    2000.times {
      from = Hash[*(gen_str.split(//u)*2)]
      to   = Hash[*(gen_str.split(//u)*2)]
      from.stroke_patch(from.stroke_diff(to)).should == to
    }
  end
  
  [ nil,
    1, 2**64, -1.0,
    :sym,
    "string",
    [:arr, 1],
    @obj
  ].each do |obj|
    it "should correctly patch hash with a replacement #{obj.inspect}" do
      @arr.stroke_patch(@arr.stroke_diff(obj)).should == obj
    end
  end
  
  it "should correctly patch hash with objects" do
    arr = (1..10).to_a.map{ Object.new }
    a = Hash[1, arr[0], 2, arr[2], 3, arr[3], 4, arr[4], 5, arr[8]]
    b = Hash[1, arr[1], 2, arr[2], 3, arr[3], 4, arr[8], 5, arr[9], 6, arr[4], 7, arr[1]]
    a.stroke_patch(a.stroke_diff(b)).should == b
  end
  
  def gen_str
    letters = %w(a b c d)
    str = ""
    len = rand(letters.size*2)
    len.times {
      str << letters[rand(letters.size)]
    }
    str
  end
end

describe "Automerging hashes" do
  
  before(:each) do
    @base = {:a => 1, :b => 2, :c =>3}
  end
  
  it "should do a trivial merge" do
    a = @base.merge :a => 2, :x => 1
    b = @base.merge :b => 3, :y => 2
    c, r1, r2 = @base.stroke_merge(@base.stroke_diff(a), @base.stroke_diff(b))
    c.should be_false
    r1.should == r2
    r2.should == @base.merge(:a => 2, :x => 1, :b => 3, :y => 2)
  end
  
  it "should do a trivial merge with missing slots" do
    b1 = @base.dup; b1.delete(:a)
    b2 = @base.dup; b2.delete(:b)
    a = b1.merge :x => 2
    b = b2.merge :y => 3
    c, r1, r2 = @base.stroke_merge(@base.stroke_diff(a), @base.stroke_diff(b))
    c.should be_false
    r1.should == r2
    r2.should == {:c => @base[:c], :x => 2, :y => 3}
  end
  
  it "should merge intersecting, but identical old slots" do
    a = @base.merge :a => 2, :c => 42
    b = @base.merge :b => 3, :c => 42
    c, r1, r2 = @base.stroke_merge(@base.stroke_diff(a), @base.stroke_diff(b))
    c.should be_false
    r1.should == r2
    r2.should == @base.merge(:a => 2, :b => 3, :c => 42)
  end
  
  it "should merge intersecting, but identical new slots" do
    a = @base.merge :a => 2, :x => 42
    b = @base.merge :b => 3, :x => 42
    c, r1, r2 = @base.stroke_merge(@base.stroke_diff(a), @base.stroke_diff(b))
    c.should be_false
    r1.should == r2
    r2.should == @base.merge(:a => 2, :b => 3, :x => 42)
  end
    
end

describe "Merge conflicts in hashes" do
  
  before(:each) do
    @base = {:a => 1, :b => 2, :c =>3}
  end
  
  
end



