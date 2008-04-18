require File.dirname(__FILE__) + '/spec_helper'

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
    should_merge(@base, a, b, @base.merge(:a => 2, :x => 1, :b => 3, :y => 2))
  end
  
  it "should do a trivial merge with missing slots" do
    b1 = @base.dup; b1.delete(:a)
    b2 = @base.dup; b2.delete(:b)
    a = b1.merge :x => 2
    b = b2.merge :y => 3
    should_merge(@base, a, b, {:c => @base[:c], :x => 2, :y => 3})
  end
  
  it "should merge intersecting, but identical old slots" do
    a = @base.merge :a => 2, :c => 42
    b = @base.merge :b => 3, :c => 42
    should_merge(@base, a, b, @base.merge(:a => 2, :b => 3, :c => 42))
  end
  
  it "should merge intersecting, but identical new slots" do
    a = @base.merge :a => 2, :x => 42
    b = @base.merge :b => 3, :x => 42
    should_merge(@base, a, b, @base.merge(:a => 2, :b => 3, :x => 42))
  end
  
  it "should merge deep diffed slots" do
    base = {:s => { :a => 1 }}
    a    = {:s => { :a => 2 }}
    b    = {:s => { :a => 1, :b => 3 }}
    should_merge(base, a, b, {:s => { :a => 2, :b => 3 }})
  end
  
  it "should merge same slot deletion" do
    should_merge({:a => 1, :b => 2}, {:b => 2}, {:b => 3}, {:b => 3})
    should_merge({:a => 1, :b => 2}, {:b => 2}, {:b => 2}, {:b => 2})
  end
  
  it "should merge when one of the objects is the same" do
    bases = [{:a => 1}, {:a => 1, :b => 2}, {:a => 1, :b => 2}]
    bs    = [{:a => 3}, {:a => 1}, {:b => "22"}, nil, 123, Object.new, :symb, false, true]
    
    bases.each do |base|
      bs.each do |b|
        should_merge(base, base, b, b)
      end
    end
  end
end

describe "Merge conflicts in hashes" do
  
  it "should yield a diff-diff conflict with partial merge" do
    base = {:a => 1,   :b => 2,   :c =>3}
    a    = {:a => 111, :b => 222, :c =>3}
    b    = {:a => 222, :b => 2,   :c =>333}
    ra   = {:a => 111, :b => 222, :c =>333}
    rb   = {:a => 222, :b => 222, :c =>333}
    should_yield_conflict(base, a, b, ra, rb)
  end
    
  it "should yield a deletion-diff conflict with partial merge" do
    base = {:a => 1,   :b => 2,   :c =>3}
    a    = {           :b => 222, :c =>3}
    b    = {:a => 222, :b => 2,   :c =>333}
    ra   = {           :b => 222, :c =>333}
    rb   = {:a => 222, :b => 222, :c =>333}
    should_yield_conflict(base, a, b, ra, rb)
  end
  
  it "should yield a insertion-insertion conflict with partial merge" do
    base = {           :b => 2,   :c =>3}
    a    = {:a => 111, :b => 222, :c =>3}
    b    = {:a => 222, :b => 2,   :c =>333}
    ra   = {:a => 111, :b => 222, :c =>333}
    rb   = {:a => 222, :b => 222, :c =>333}
    should_yield_conflict(base, a, b, ra, rb)
  end
  
  it "should yield a deep diff-diff conflict with partial merge" do
    base = {:s => { :a => 1, :b => 2,  :c => 3  }, :del => 1 }
    a    = {:s => { :a => 2, :b => 22, :c => 3  }, :del => 1, :x => 1 }
    b    = {:s => { :a => 3, :b => 2,  :c => 33 }}
    ra   = {:s => { :a => 2, :b => 22, :c => 33 }, :x => 1}
    rb   = {:s => { :a => 3, :b => 22, :c => 33 }, :x => 1}
    should_yield_conflict(base, a, b, ra, rb)
  end
end



