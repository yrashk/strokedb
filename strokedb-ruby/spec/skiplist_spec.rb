require File.dirname(__FILE__) + '/spec_helper'

describe "Non-empty skiplist" do
  
  before(:each) do
    @list = Skiplist.new("a"   => "1", 
                         "aa"  => "2",
                         "aaa" => "3",
                         "p"   => "4")
  end

	it "should create" do
		@list.should_not be_empty
	end
	
	it "should have size" do
		@list.size.should == 4
	end

	it "should find" do
		@list.find("a").should   == "1"
		@list.find("aaa").should == "3"
	end

	it "should give default if nothing found" do
		@list.find("404").should == nil
	end
	
	it "should give local default if nothing found" do
		@list.find("404", :default_value).should == :default_value
	end
	
	it "should insert data" do
	  @list.insert("b", "3.5")
	  @list.find("b").should == "3.5"
	end

	it "should replace data" do
	  @list.insert("aaa", "3.5")
	  @list.find("aaa").should == "3.5"
	end
	
	it "should delete node by key" do
	  @list.delete("aaa").should == "3"
	  @list.find("aaa").should == nil
	end
	
	it "should not delete not found key" do
	  @list.find("404").should == nil
	  @list.delete("404").should == nil
	  @list.find("404").should == nil
	end
	
end


describe "Empty big skiplist" do
  
  before(:each) do
    @list = Skiplist.new
  end

  it "should be empty" do
    @list.should be_empty
    @list.size.should == 0
  end
  
  it "should be empty with each" do
    a = b = "each{ } did not yield"
    @list.each{|n| a = "each{ } did yield!" }
    a.should == b
  end
  
  it "should not find anything" do
    @list.find("a").should == nil
    @list.find("").should == nil
    @list.find("aaa").should == nil
    @list.find(123).should == nil
    @list.find(-1).should == nil
  end
  
  it "should not delete anything" do
    @list.delete("a").should == nil
    @list.delete("a").should == nil
    @list.delete("").should == nil
    @list.delete("aaa").should == nil
    @list.delete(123).should == nil
    @list.delete(-1).should == nil
  end
end



describe "Non-empty big skiplist" do
  
  before(:each) do
    a = []
    100.times { |i|
      a << "#{i}"
      a << "#{rand(100)}"
    }
    @list = Skiplist.new(Hash[*a])
  end

  it "should contain all the items" do
    #puts @list.to_s_levels
  end
end



describe "Skiplist search" do
  before(:each) do
    @times = 100
    @start = 1024
    @ratio = 2
    @lists = [@start, @start*@ratio, @start*@ratio*@ratio].map do |len|
      list = Skiplist.new
      len.times do |i|
        list.insert(i, rand)
      end
      list
    end
  end
  
  it "should be O(log(n))" do
    t1 = time(@times, @lists[0])
    t2 = time(@times, @lists[1])
    t3 = time(@times, @lists[2])
    
    r1 = Math.log(t2/t1)
    r2 = Math.log(t3/t2)
    
    #p [t1, t2, t3]
    #p [r1, r2]
    
    # r1.should == r2
  end
  
  def time(n, list)
    GC.start
    t = Time.now
    s = list.size
    n.times { list.find(rand(s)) }
    Time.now - t
  ensure
    GC.start
  end
end 






