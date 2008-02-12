require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Initial LamportTimestamp" do
  before(:each) do
    @t0   = LamportTimestamp.new()
  end
  
  it "should have counter == 0" do
    @t0.counter.should == 0
  end
  
  it "should have random salt" do
    @t0.salt.should > -1
  end
end


describe "Preset LamportTimestamp" do
  before(:each) do
    @t0   = LamportTimestamp.new()
    @t123 = LamportTimestamp.new(123)
    @t234 = LamportTimestamp.new(234)
  end
  
  it "should be compared properly" do
    (@t0   <=> @t123).should  == -1
    (@t123 <=> @t234).should  == -1
  end

  it "should have random salt" do
    @t123.salt.should > -1
    @t234.salt.should > -1
  end
end


describe "LamportTimestamp equality" do
  before(:each) do
    @t = LamportTimestamp.new(123)
    @t_dumped = Marshal.dump(@t)
    @t_loaded = Marshal.load(@t_dumped)
  end
  
  # Positive
  it { @t.should == @t }
  it { @t.should == @t_loaded }
  it "should correctly compare tons of dumped-loaded timestamps" do
    1000.times do
      t = LamportTimestamp.new(rand(2**64))
      t.should == Marshal.load(Marshal.dump(t))
    end
  end
  
  # Negative
  it { LamportTimestamp.new().should_not == LamportTimestamp.new() }
  it { LamportTimestamp.new(123).should_not == LamportTimestamp.new(123) }
  it { LamportTimestamp.new(234).should_not == LamportTimestamp.new(234) }
  it { 1000.times { @t.next.should_not == @t.next  } }
end


describe "LamportTimestamp comparison" do
  before(:each) do
    @t0   = LamportTimestamp.new()
    @t123 = LamportTimestamp.new(123)
  end
  
  it "should be compared with <" do
    @t0.should < @t123
    @t123.should_not < @t0
  end
  
  it "should be compared with <=" do
    @t0.should <= @t123
    @t123.should <= @t123
    @t123.should_not <= @t0
  end

  it "should be compared with >" do
    @t123.should > @t0
    @t123.should_not > @t123
    @t0.should_not > @t123
  end
  
  it "should be compared with >=" do
    @t123.should >= @t0
    @t123.should >= @t123
    @t0.should_not >= @t123
  end
  
  it { 1000.times { t = LamportTimestamp.new(rand(2**64)); t.next.next.should > t.next } }
  
  it "should generate a list of successive timestamps with next!" do 
    t = LamportTimestamp.new(rand(2**32))
    1000.times do
      t_ = t.dup
      t.next!
      t_.should < t
      t_.salt.should == t.salt
    end 
  end
end

describe "LamportTimestamp maximum counter exception" do
  it "should raise error if counter is too big" do
    lambda { LamportTimestamp.new(2**64 + 1) }.should raise_error(LamportTimestamp::CounterOverflow)
  end
  it "should not raise error if counter is 2**64" do
    lambda { LamportTimestamp.new(2**64) }.should_not raise_error
    lambda { LamportTimestamp.new(2**64-1) }.should_not raise_error
  end
  it "should raise error on LamportTimestamp#next" do
    lambda { LamportTimestamp.new(2**64).next }.should raise_error(LamportTimestamp::CounterOverflow)
  end
  it "should not raise error on LamportTimestamp#next if no overflow occured" do
    lambda { LamportTimestamp.new(2**64 - 1).next }.should_not raise_error
  end
end


describe "LamportTimestamp raw format" do
  before(:each) do
    @t = LamportTimestamp.new(123)
  end
  it "should convert to simple string" do
    @t.to_raw.should == @t.to_s
  end
  it "should correctly convert end-to-end" do
    LamportTimestamp.from_raw(@t.to_raw).should == @t 
  end
end

