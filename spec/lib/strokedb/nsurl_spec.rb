require File.dirname(__FILE__) + '/spec_helper'

describe "Some", Module do
  
  before(:each) do
    @module = Module.new
    Module.reset_nsurls
  end
  
  after(:each) do
    Module.reset_nsurls
  end
  
  it "should have nil nsurl by default" do
    @module.nsurl.should be_nil
  end
  
  it "should be able to change nsurl" do
    @module.nsurl 'http://some.url'
    @module.nsurl.should == 'http://some.url'
  end
  
  it "should be findable by nsurl" do
    @module.nsurl 'http://some.url'
    Module.find_by_nsurl(@module.nsurl).should == @module
  end
  
  it "should be able to change nsurl to the same value" do
    @module.nsurl 'http://some.url'
    lambda { @module.nsurl 'http://some.url' }.should_not raise_error(ArgumentError)
  end

  it "should not be able to change nsurl to the value already assigned to some module" do
    @some_module = Module.new
    @some_module.nsurl 'http://some.url'
    lambda { @module.nsurl 'http://some.url' }.should raise_error(ArgumentError)
  end
  
end

describe Module do
  
  
  before(:each) do
    Module.reset_nsurls
  end
  
  after(:each) do
    Module.reset_nsurls
  end

  
  it "should have empty nsurl by default" do
    Module.nsurl.should be_empty
  end
  
end

describe StrokeDB do
  
  before(:each) do
    Module.reset_nsurls
  end

  after(:each) do
    Module.reset_nsurls
  end
  
  it "should have #{STROKEDB_NSURL} nsurl by default" do
    StrokeDB.nsurl.should == STROKEDB_NSURL
  end
  
end