require File.dirname(__FILE__) + '/spec_helper'

describe "Complex diff" do
  objs = [
    [1,2,"str"]
  ]
  it "should patch scalar" do
    1000.times do 
      a = gen_complex_object
      b = gen_complex_object
      unless a.stroke_patch(a.stroke_diff(b)) == b
        puts ""
        puts "a = #{a.inspect}"
        puts "b = #{b.inspect}"
        puts "a.stroke_diff(b)"
        puts "a.stroke_patch(a.stroke_diff(b))"
      end
      a.stroke_patch(a.stroke_diff(b)).should == b
    end
  end
  
  def gen_complex_object
    scalars = [1, :sym, false, true, nil, :hash, :array, :string]
    s = scalars[rand(scalars.size)]
    case s
    when :hash
      gen_hash
    when :array
      gen_array
    when :string
      gen_string
    else
      s
    end
  end
  
  def gen_hash
    keys = gen_string.split(//u)
    keys.inject({}) do |h, k|
      h[k] = gen_complex_object
      h
    end
  end

  def gen_array
    len = rand(4*2)
    (1..len).to_a.map{ gen_complex_object }
  end
  
  def gen_string
    letters = %w(a b c d)
    (1..rand(letters.size*2)).inject("") { |s, l|
      s << letters[rand(letters.size)]
      s
    }
  end
  
end
