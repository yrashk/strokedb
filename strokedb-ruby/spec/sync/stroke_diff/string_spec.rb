require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

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
    it { @str.stroke_patch(@str.stroke_diff(obj)).should == obj }
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
