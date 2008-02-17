require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

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
    it "should correctly patch array with a replacement diff" do
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
