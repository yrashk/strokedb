require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

def should_merge(base, a, b, r)
  c, r1, r2 = base.stroke_merge(base.stroke_diff(a), base.stroke_diff(b))
  c.should be_false
  r1.should == r
  r2.should == r
  # another order
  c, r1, r2 = base.stroke_merge(base.stroke_diff(b), base.stroke_diff(a))
  c.should be_false
  r1.should == r
  r2.should == r
end

def should_yield_conflict(base, a, b, ra, rb)
  c, r1, r2 = base.stroke_merge(base.stroke_diff(a), base.stroke_diff(b))
  c.should be_true
  r1.should == ra
  r2.should == rb
  # another order
  c, r1, r2 = base.stroke_merge(base.stroke_diff(b), base.stroke_diff(a))
  c.should be_true
  r1.should == rb
  r2.should == ra
end