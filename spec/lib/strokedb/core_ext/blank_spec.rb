require File.dirname(__FILE__) + '/spec_helper'


describe "fasle" do
  it "should be blank" do
    false.should be_blank
  end
end

describe "true" do
  it "should not be blank" do
    true.should_not be_blank
  end
end

describe "Numeric" do
  it "should not be blank" do
    Numeric.should_not be_blank
  end
end