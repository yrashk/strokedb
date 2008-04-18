require File.dirname(__FILE__) + '/spec_helper'

describe "Array diff" do
  
  before(:each) do
    @arr = [1, 2]
    @obj = Object.new
  end
  
  it "should correctly patch array with array diff" do
    2000.times {
      from = gen_str.split(//u)
      to   = gen_str.split(//u)
      from.stroke_patch(from.stroke_diff(to)).should == to
    }
  end
  
  [ nil,
    1, 2**64, -1.0,
    :sym,
    "string",
    {:arr => 1},
    @obj
  ].each do |obj|
    it "should correctly patch array with a replacement #{obj.inspect}" do
      @arr.stroke_patch(@arr.stroke_diff(obj)).should == obj
    end
  end
  
  it "should correctly patch array with objects" do
    arr = (1..10).to_a.map{ Object.new }
    a = [arr[0], arr[2], arr[3], arr[4], arr[8]]
    b = [arr[1], arr[2], arr[3], arr[8], arr[9], arr[4], arr[1]]
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

describe "Automerging arrays" do
  
  before(:each) do
    @base = [1, 2, 3]
  end
  
  it "should do a trivial one-side merge" do
    a = [1, 2, 3]
    b = [1, 2, 4, 3]
    should_merge(@base, a, b, [1, 2, 4, 3])
  end

  it "should do a trivial two-side merge" do
    a = [   1, 2, 3, 4]
    b = [0, 1, 2, 3   ]
    should_merge(@base, a, b, [0, 1, 2, 3, 4])
    
    a = [       1, 2, 3, 4, 5]
    b = [-1, 0, 1, 2, 3   ]
    should_merge(@base, a, b, [-1, 0, 1, 2, 3, 4, 5])
  end
  
  it "should do a trivial merge with missing elements" do
    a = [   1, 2, 4]
    b = [0, 1, 2, 3]
    should_merge(@base, a, b, [0, 1, 2, 4])
  end
  
  # it "should merge same slot deletion" do
  #   should_merge({:a => 1, :b => 2}, {:b => 2}, {:b => 3}, {:b => 3})
  #   should_merge({:a => 1, :b => 2}, {:b => 2}, {:b => 2}, {:b => 2})
  # end
  # 
  # it "should merge when one of the objects is the same" do
  #   bases = [{:a => 1}, {:a => 1, :b => 2}, {:a => 1, :b => 2}]
  #   bs    = [{:a => 3}, {:a => 1}, {:b => "22"}, nil, 123, Object.new, :symb, false, true]
  #   
  #   bases.each do |base|
  #     bs.each do |b|
  #       should_merge(base, base, b, b)
  #     end
  #   end
  # end
  
  
end




