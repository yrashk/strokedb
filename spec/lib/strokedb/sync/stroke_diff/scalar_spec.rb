require File.dirname(__FILE__) + '/spec_helper'

describe "Scalar diff" do

  scalars = [
      1, -1, 12345678901234567890,
      3.1415926, 2.71828182, -0.333,
      :sym1, :sym2,
      false, true, nil,
      Object.new, Object.new  # okay, these are not scalaras, but relevant to the spec
    ]
  
  scalars.each do |s1|
    it "should patch scalar #{s1.inspect}" do
      scalars.each do |s2|
        s1.stroke_patch(s1.stroke_diff(s2)).should == s2
      end
    end
  end
end


# TODO: spec merging
