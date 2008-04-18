require File.dirname(__FILE__) + '/spec_helper'

describe "LamportTimestamp" do
  it "#zero_string" do
    LamportTimestamp.zero_string.should == '000000000000000000000000-0000-0000-0000-000000000000'
  end
end

describe "Initial LamportTimestamp" do
  before(:each) do
    @t0 = LamportTimestamp.new
  end

  it "should have counter == 0" do
    @t0.counter.should == 0
  end

  it "should have UUID-based uuid" do
    @t0.uuid.should match(UUID_RE)
  end

  it "should pass generated uuid on #next" do
    @t0.next.uuid.should == @t0.uuid
  end
  
  it "shoul return marshal_dump as json" do
    @t0.to_json.should == '"0000000000000000'+@t0.uuid+'"'
  end
end


describe "Initial LamportTimestamp with uuid specified" do
  before(:each) do
    @t0   = LamportTimestamp.new(0,NIL_UUID)
  end

  it "should have counter == 0" do
    @t0.counter.should == 0
  end

  it "should have UUID-based uuid as defined" do
    @t0.uuid.should == NIL_UUID
  end

  it "should pass uuid on #next" do
    @t0.next.uuid.should == @t0.uuid
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

  it "should have UUID-based uuid" do
    @t123.uuid.should match(UUID_RE)
    @t234.uuid.should match(UUID_RE)
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
end


describe "Lesser and greater LamportTimestamps" do
  before(:each) do
    @t0   = LamportTimestamp.new()
    @t123 = LamportTimestamp.new(123)
  end

  it "should be comparable with <" do
    @t0.should < @t123
    @t123.should_not < @t0
  end

  it "should be comparable with <=" do
    @t0.should <= @t123
    @t123.should <= @t123
    @t123.should_not <= @t0
  end

  it "should be comparable with >" do
    @t123.should > @t0
    @t123.should_not > @t123
    @t0.should_not > @t123
  end

  it "should be comparable with >=" do
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
      t_.uuid.should == t.uuid
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
  it "should compare raw representation exactly like object representation" do
    1000.times do
      t1 = LTS.new(rand(2**32))
      t2 = LTS.new(rand(2**32))
      object_comparison = (t1 <=> t2)
      raw_comparison = (t1.to_raw <=> t2.to_raw)
      object_comparison.should == raw_comparison
    end
  end
end

