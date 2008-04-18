require File.dirname(__FILE__) + '/spec_helper'

describe "Chain sync" do
  include ChainSync
  before(:each) do
    @chain1 = %w[ a b c     ]
    @chain2 = %w[ a b c d e ]
    @chain3 = %w[ a b q w r ]
    @chain4 = %w[ t y u i o ]
  end
  
  it "should raise NonMatchingChains for non-matching chains" do
    lambda{ sync_chains(@chain1, @chain4) }.should raise_error(ChainSync::NonMatchingChains)
    lambda{ sync_chains(@chain4, @chain1) }.should raise_error(ChainSync::NonMatchingChains)
  end
  
  it "should not raise NonMatchingChains for matching chains" do
    lambda{ sync_chains(@chain1, @chain2) }.should_not raise_error
    lambda{ sync_chains(@chain1, @chain3) }.should_not raise_error
    lambda{ sync_chains(@chain2, @chain3) }.should_not raise_error
    lambda{ sync_chains(@chain2, @chain1) }.should_not raise_error
    lambda{ sync_chains(@chain3, @chain1) }.should_not raise_error
    lambda{ sync_chains(@chain3, @chain2) }.should_not raise_error
  end

  it "should resolve up-to-date situation" do
    sync_chains(@chain1, @chain2).should == :up_to_date
    sync_chains(@chain2, @chain1).should_not == :up_to_date
  end
  
  it "should resolve fast-forward situation" do
    status, subchain = sync_chains(@chain2, @chain1)
    status.should == :fast_forward
    subchain.should == %w[ c d e ]
  end
  
  it "should resolve merge situation" do
    status, subchain_from, subchain_to = sync_chains(@chain2, @chain3)
    status.should == :merge
    subchain_from.should == %w[ b c d e ]
    subchain_to.should   == %w[ b q w r ]
  end
end
