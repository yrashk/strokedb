require File.dirname(__FILE__) + '/spec_helper'

# Skiplist development plan:
# 1) Version 2
# 2) Version 2 + sorting
# 3) Version 2 + chunking.

describe KDSkiplist2, "basic single record finder" do

  before(:all) do
    @kd = KDSkiplist2.new
    @lisbon = { :name => 'Lisbon', :x => -9, :y => 37 }
    @kd.insert(@lisbon)
  end
    
  # Positive
  
  it "should find by two ranges" do
    @kd.find(:x => -10..0, :y => 30..40).should == [ @lisbon ]
  end
  
  it "should find by one range" do
    @kd.find(:x => -10..0).should == [ @lisbon ]
    @kd.find(:y => 30..40).should == [ @lisbon ]
  end

  it "should find in a (semi-)infinite range" do
    # x
    @kd.find(:x => [nil, 0], :y => 30..40).should == [ @lisbon ]
    @kd.find(:x => [nil, 0]).should == [ @lisbon ]
    @kd.find(:x => [-10, nil], :y => 30..40).should == [ @lisbon ]
    @kd.find(:x => [-10, nil]).should == [ @lisbon ]
    @kd.find(:x => [nil, nil]).should == [ @lisbon ]
    
    # y
    @kd.find(:y => [nil, 37], :x => -30..40).should == [ @lisbon ]
    @kd.find(:y => [nil, 37]).should == [ @lisbon ]
    @kd.find(:y => [37, nil], :x => -30..40).should == [ @lisbon ]
    @kd.find(:y => [37, nil]).should == [ @lisbon ]
    @kd.find(:y => [nil, nil]).should == [ @lisbon ]
  end
  
  it "should find by single value" do
    @kd.find(:x => -9, :y => 37).should == [ @lisbon ]
    @kd.find(:x => -9).should == [ @lisbon ]
    @kd.find(:y => 37).should == [ @lisbon ]
  end
  
  it "should find by string" do
    @kd.find(:name => 'Lisbon', :x => -10..10, :y => 30..40).should == [ @lisbon ]
    @kd.find(:name => 'Lisbon', :x => -10..10).should == [ @lisbon ]
    @kd.find(:name => 'Lisbon').should == [ @lisbon ]
  end
  
  it "should find by string range" do
    @kd.find(:name => %w[L M],    :x => -10..10, :y => 30..40).should == [ @lisbon ]
    @kd.find(:name => %w[La Lo],  :x => -10..10).should == [ @lisbon ]
    @kd.find(:name => %w[Lisbon Lisbon2]).should == [ @lisbon ]
  end
    
  # Negative
  
  it "should not find by a single wrong range" do
    @kd.find(:x => -5..0).should  == [  ]
    @kd.find(:y => 38..40).should == [  ]
  end
  
  it "should not find by a wrong range with right range" do
    @kd.find(:x => -10..0, :y => 39..40).should == [  ]
    @kd.find(:x => -5..0,  :y => 30..40).should == [  ]
  end
  
  it "should not find by wrong string" do
    @kd.find(:name => 'Lisbon1', :x => -10..10, :y => 30..40).should == [  ]
    @kd.find(:name => 'Lisbon2', :x => -10..10).should == [  ]
    @kd.find(:name => 'Lisbon3').should == [  ]
  end
end



describe KDSkiplist2, "basic multiple records finder" do

  before(:all) do
    @kd = KDSkiplist2.new(:name)
    @vancouver  = { :name => 'Vancouver', :x => -123, :y =>  48 }
    @newyork    = { :name => 'New York',  :x => -73,  :y =>  42 }
    @lisbon     = { :name => 'Lisbon',    :x => -9,   :y =>  37 }
    @london     = { :name => 'London',    :x =>  0,   :y =>  52 }
    @naples     = { :name => 'Naples',    :x =>  14,  :y =>  41 }
    @durban     = { :name => 'Durban',    :x =>  31,  :y => -30 }
    @singapore  = { :name => 'Singapore', :x =>  104, :y =>  2  }
    @tokyo      = { :name => 'Tokyo',     :x =>  140, :y =>  37 }
    @sydney     = { :name => 'Sydney',    :x =>  150, :y => -34 }
      
    @kd.insert(@newyork)
    @kd.insert(@london)
    @kd.insert(@naples)
    @kd.insert(@vancouver)
    @kd.insert(@tokyo)
    @kd.insert(@sydney)
    @kd.insert(@durban)
    @kd.insert(@lisbon)
    @kd.insert(@singapore)
  end
    
  # Positive
  
  it "should find by two ranges" do
    @kd.find(:x => -9..14, :y => 37..52).to_set.should == [ @lisbon, @london, @naples ].to_set
  end
  
  it "should find by one range" do
    @kd.find(:name => 'L'..'Lz').to_set.should == [ @lisbon, @london ].to_set
  end
  
  it "should find by prefix syntax :slot => 'prefi*'" do
    @kd.find(:name => 'N*').to_set.should == [ @newyork, @naples ].to_set
  end
  
  # Negative
  
  
  
end


describe KDSkiplist2, "with duplicate keys" do
  before(:each) do
    @kd = KDSkiplist2.new(:name)
  end
  it "should store records separately" do
    @vasya = { :name => 'Vasya', :age => 18 }
    @petya = { :name => 'Petya', :age => 18 }
    @kd.insert(@vasya)
    @kd.insert(@petya)
    @kd.find(:name => "Vasya").should == [ @vasya ]
    @kd.find(:name => "Petya").should == [ @petya ]
    @kd.find(:age  => 18).to_set.should == [ @vasya, @petya ].to_set
  end
end


describe KDSkiplist2 do

  before(:each) do
    @kd = KDSkiplist2.new
  end

  it "should sort data by one of the keys" do
    pending
  end
  
  it "should accept any object with #[] method" do
    pending
  end
  
end

