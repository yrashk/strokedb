require File.dirname(__FILE__) + '/spec_helper'

describe "String diff" do
  
  before(:each) do
    @str = "str"
    @obj = Object.new
  end
  
  it "should correctly patch string with string diff" do
    2000.times {
      from = gen_str
      to   = gen_str
      from.stroke_patch(from.stroke_diff(to)).should == to
    }
  end
  
  [ nil,
    1, 2**64, -1.0,
    :sym,
    [:arr],
    {:arr => 1},
    @obj
  ].each do |obj|
    it "should correctly patch string with a replacement #{obj.inspect}" do
      @arr.stroke_patch(@arr.stroke_diff(obj)).should == obj
    end
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

describe "String automerge" do
  
  it "should do a trivial merge" do
  #  should_merge("abc", "abcd", "axc", "axcd")
  end
  
  
  def should_merge(base, a, b, r)
    c, r1, r2 = base.stroke_merge(base.stroke_diff(a), base.stroke_diff(b))
    c.should be_false
    r1.should == r1
    r2.should == r
    # another order
    c, r1, r2 = base.stroke_merge(base.stroke_diff(b), base.stroke_diff(a))
    c.should be_false
    r1.should == r1
    r2.should == r
  end

end

