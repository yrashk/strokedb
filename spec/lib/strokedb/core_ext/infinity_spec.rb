require File.dirname(__FILE__) + '/spec_helper'

describe "Object#infinity?" do
  it "should return false for the finite values" do
    Object.should_not be_infinite
    Object.new.should_not be_infinite
    String.new.should_not be_infinite
    Time.now.should_not be_infinite
    :sym.should_not be_infinite
    nil.should_not be_infinite
    false.should_not be_infinite
    true.should_not be_infinite
    Float::MAX.should_not be_infinite
    2.71828.should_not be_infinite
    42.should_not be_infinite
    (1..Infinity).should_not be_infinite # yep, this too.
  end
  it "should return true for infinite 'values'" do
    Infinity.should be_infinite
    (-Infinity).should be_infinite
    (InfinityString).should be_infinite
    (InfinityTime).should be_infinite
  end 
end

describe InfinityString do
  it "should be used in Range" do
    (InfinityString.."a").should be_a_kind_of(Range)
    ("a"..InfinityString).should be_a_kind_of(Range)
    (InfinityString..InfinityString).should be_a_kind_of(Range)
  end
end

describe InfinityTime do
  it "should be used in Range" do
    (InfinityTime..Time.now).should be_a_kind_of(Range)
    (Time.now..InfinityTime).should be_a_kind_of(Range)
    (InfinityTime..InfinityTime).should be_a_kind_of(Range)
  end
end
