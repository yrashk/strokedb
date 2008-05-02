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
    (InfiniteString).should be_infinite
    (InfiniteTime).should be_infinite
  end 
end

describe InfiniteString do
  it "should be used in Range" do
    (InfiniteString.."a").should be_a_kind_of(Range)
    ("a"..InfiniteString).should be_a_kind_of(Range)
    (InfiniteString..InfiniteString).should be_a_kind_of(Range)
  end
end

describe InfiniteTime do
  it "should be used in Range" do
    (InfiniteTime..Time.now).should be_a_kind_of(Range)
    (Time.now..InfiniteTime).should be_a_kind_of(Range)
    (InfiniteTime..InfiniteTime).should be_a_kind_of(Range)
  end
end
