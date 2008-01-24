require File.dirname(__FILE__) + '/spec_helper'

describe "Non-empty skiplist" do
  
  before(:each) do
    @list = Skiplist.new("a"   => "1", 
                         "aa"  => "2",
                         "aaa" => "3",
                         "p"   => "4",
                         "123.1" => "v1",
                         "123.2" => "v2",
                         "123" => "v0")
  end

	it "should not be empty" do
		@list.should_not be_empty
	end
	
	it "should have size" do
	  @list.should have(7).items
	end

	it "should find" do
		@list.find("a").should   == "1"
		@list.find("aaa").should == "3"
	end
	
	it "should find entries with prefix" do
	  @list.find_all_with_prefix("123").to_set.should == ["v1","v2","v0"].to_set
  end

  it "should find default value if search with prefix returns nothing" do
    @list.find_all_with_prefix("nothinglike123",123).should == 123
  end

	it "should return default value if nothing found" do
		@list.find("404").should be_nil
	end
	
	it "should give local default value if nothing found" do
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
	  @list.find("aaa").should be_nil
	end
	
	it "should not delete non-existent key" do
	  @list.find("404").should be_nil
	  @list.delete("404").should be_nil
	  @list.find("404").should be_nil
	end
	
	it "should find by first nearest key" do
	  @list.find_nearest("0").should   == "v0"
	  @list.find_nearest("a").should   == "1"
    @list.find_nearest("aa").should  == "2"
    @list.find_nearest("aa0").should == "2"
    @list.find_nearest("aaa").should == "3"
    @list.find_nearest("ab").should  == "3"
    @list.find_nearest("d").should   == "3"
    @list.find_nearest("xxx").should == "4"
	end
	
end


describe "Empty big skiplist" do
  
  before(:each) do
    @list = Skiplist.new
  end

  it "should be empty" do
    @list.should be_empty
    @list.should have(0).items 
  end
  
  it "should be empty with #each iteratpr" do
    a = b = "each{ } did not yield"
    @list.each{|n| a = "each{ } did yield!" }
    a.should == b
  end
  
  it "should not find anything" do
    @list.find("a").should be_nil
    @list.find("").should be_nil
    @list.find("aaa").should be_nil
    @list.find(123).should be_nil
    @list.find(-1).should be_nil
  end
  
  it "should not delete anything" do
    @list.delete("a").should be_nil
    @list.delete("a").should be_nil
    @list.delete("").should be_nil
    @list.delete("aaa").should be_nil
    @list.delete(123).should be_nil
    @list.delete(-1).should be_nil
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
    @start = 128
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






