require File.dirname(__FILE__) + '/spec_helper'

describe "Kernel#extract" do
  
  it "should correctly extract various arguments" do
    extract(Regexp, String, Hash, [          ]).should == [nil, nil, nil]
    
    extract(Regexp, String, Hash, [/a/       ]).should == [/a/, nil, nil]
    extract(Regexp, String, Hash, [    "a"   ]).should == [nil, "a", nil]
    extract(Regexp, String, Hash, [    {1=>2}]).should == [nil, nil, {1=>2}]
    
    extract(Regexp, String, Hash, [//, ""    ]).should == [//,  "",  nil]
    extract(Regexp, String, Hash, [//,     {}]).should == [//,  nil, {} ]
    extract(Regexp, String, Hash, [    "", {}]).should == [nil,  "",  {}]
    
    extract(Regexp, String, Hash, [//, "", {}]).should == [//,  "",  {} ]
  end
  
  it "should raise ArgumentError when wrong arguments are passed" do
    
    bad_case(Regexp, String, Hash, [123])
    bad_case(Regexp, String, Hash, ["", //])
    bad_case(Regexp, String, Hash, [{}, ""])
    bad_case(Regexp, String, Hash, [true])
    bad_case(Regexp, String, Hash, [false])
    bad_case(Regexp, String, Hash, [//,false])
    bad_case(Regexp, String, Hash, [nil])
    bad_case(Regexp, String, Hash, ["", nil])
    bad_case(Regexp, String, Hash, [nil, nil])
    bad_case(Regexp, String, Hash, [{}, {}])
    bad_case(Regexp, String, Hash, [//, //])
    bad_case(Regexp, String, Hash, [ [] ])
    bad_case(Regexp, String, Hash, [Object.new])
    bad_case(Regexp, String, Hash, [Object.new, Object.new])
    
  end
  
  def bad_case(*args)
    lambda { extract(*args) }.should raise_error(ArgumentError)
  end
  
end