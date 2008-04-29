require File.dirname(__FILE__) + '/spec_helper'

describe "String#/" do
  it "should concatenate strings with /" do
    "lib"/"core_ext".should == "lib/core_ext"
    "lib/core_ext"/"foo".should == "lib/core_ext/foo"
  end
end

describe "String#modulize" do

  it "if there is no module, leave nothing" do
    "A".modulize.should == ""
    "::A".modulize.should == ""
  end
  
  it "should leave single module" do
    "A::B".modulize.should == "A"
  end

  it "should leave multiple modules" do
    "A::B::C".modulize.should == "A::B"
  end

end