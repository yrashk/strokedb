require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "TrueClass" do
  it "should not be blank" do
    TrueClass.should_not be_blank
  end
end

describe "Numeric" do
  it "should not be blank" do
    Numeric.should_not be_blank
  end
end