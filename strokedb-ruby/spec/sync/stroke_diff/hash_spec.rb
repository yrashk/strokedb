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
