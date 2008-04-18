require File.dirname(__FILE__) + '/spec_helper'

describe "Symbol#/" do
  it "should concatenate symbols with / as a string" do
    :lib/:core_ext.should == "lib/core_ext"
    :lib/:core_ext/:foo.should == "lib/core_ext/foo"
  end
end