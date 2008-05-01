require File.dirname(__FILE__) + '/spec_helper'

describe Infinity do

  it "should correctly compare with integers and floats" do
    Infinity.should > 1
    Infinity.should > 1.0
  end
    
  it "should correctly work with ranges" do
    (-Infinity..1).should include(-100)
    (-Infinity..Infinity).should include(Float::MAX)
    (0..Infinity).should include(Float::MAX)
  end
  
  it "should return Infinity in arithmetics" do
    (Infinity + Infinity).should == Infinity
    (Infinity * Infinity).should == Infinity
    (Infinity ** Infinity).should == Infinity
    (Infinity / 0).should == Infinity
    (Infinity / 0.0).should == Infinity
  end
  
  it "should return NaN in arithmetics" do
    (Infinity - Infinity).should be_nan
    (Infinity / Infinity).should be_nan
    (Infinity * 0).should be_nan
    (Infinity * 0.0).should be_nan
  end
  
end

describe NaN do
  
  it "should correctly compare with numerics" do
    (NaN < 1).should be_false
    (NaN > 1).should be_false
    (NaN == 1).should be_false
  end
  
  it "should not compare with itself" do
    NaN.should_not == NaN
    NaN.should be_nan
    NaN.object_id.should == NaN.object_id
    (NaN + 1).object_id.should_not == NaN.object_id
  end

  it "should produce NaN in all the operations except NaN**0 == 1" do
    (NaN + 1).should be_nan
    (NaN + Infinity).should be_nan
    (NaN - 1).should be_nan
    (NaN * 0).should be_nan
    (NaN * Infinity).should be_nan
    (NaN ** 0).should == 1  # <-- WTF?  (Ruby 1.8.6 rel. 2007-03-13)
    (NaN ** 1).should be_nan
    (NaN ** Infinity).should be_nan
    (NaN / 0).should be_nan
    (NaN / 1).should be_nan
    (NaN / Infinity).should be_nan
  end
  
end
