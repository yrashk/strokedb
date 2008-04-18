require File.dirname(__FILE__) + '/spec_helper'

describe "String#/" do
  it "should concatenate strings with /" do
    "lib"/"core_ext".should == "lib/core_ext"
    "lib/core_ext"/"foo".should == "lib/core_ext/foo"
  end
end