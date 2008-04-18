require File.dirname(__FILE__) + '/spec_helper'


describe "Skiplist serialization", :shared => true do
  it "should correctly load what it dumped" do
    dump1 = @list.marshal_dump
    newlist = @list.class.allocate
    dump2 = newlist.marshal_load(dump1).marshal_dump
    dump1.should == dump2
  end
  
  it "should correctly load to_a results" do
    arr1 = @list.to_a
    newlist = @list.class.from_a(arr1)
    arr2 = newlist.to_a
    arr1.should == arr2
  end
end

SimpleSkiplist.with_optimizations(OPTIMIZATIONS) do |lang|

  describe "Empty SimpleSkiplist [#{lang}]" do
  
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(nil, :maxlevel => @maxlevel, :probability => @probability)
    end
  
  	it "should be empty" do
  		@list.should be_empty
  	end
	
  	it "should be serialized with marshal_dump" do
  	  @list.marshal_dump.should == {
  	    :options => {
  	      :probability => @probability,
  	      :maxlevel => @maxlevel
  	    },
  	    :raw_list => [
  	      [[nil]*@maxlevel, nil, nil]
  	    ]
  	  }
    end
	
  	it "should find nil in a empty skiplist" do
  	  @list.find("xx").should == nil
  	  @list.find("").should == nil
    end
  
    it_should_behave_like "Skiplist serialization"
  end


  describe "Inserting in a skiplist [#{lang}]" do

    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(nil, :maxlevel => @maxlevel, :probability => @probability)
    end

    it "should insert empty key in place of default head" do
      @list.insert("", 42, 1).should == @list
      @list.find("").should == 42
      @list.find("-").should == nil
      @list.to_a.should == [["", 42]]
    end
  
    it "should insert non-empty key" do
      @list.insert("x", 42, 1).should == @list
      @list.find("").should == nil
      @list.find("x").should == 42
      @list.find("-").should == nil
    end
  
    it "should correctly insert keys in an ascending level order" do
      1.upto(@maxlevel) do |i|
        k = "x#{i}"
        @list.insert(k, k, i).should == @list
        @list.find("").should == nil
        @list.find(k).should == k
        @list.find("-").should == nil
      end
      # repeat
      1.upto(@maxlevel) do |i|
        k = "x#{i}"
        @list.find(k).should == k
      end
    end
  
    it "should correctly insert keys in a descending level order" do
      @maxlevel.downto(1) do |i|
        k = "x#{@maxlevel-i}"
        @list.insert(k, k, i).should == @list
        @list.find("").should == nil
        @list.find(k).should == k
        @list.find("-").should == nil
      end
      # repeat
      @maxlevel.downto(1) do |i|
        k = "x#{@maxlevel-i}"
        @list.find(k).should == k
      end
    end  
  end


  describe "Big skiplist [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(nil, :maxlevel => @maxlevel, :probability => @probability)
      1000.times do 
        k = rand(2**64).to_s
        v = k
        @list.insert(k, v)
      end
    end
  
    it_should_behave_like "Skiplist serialization"
  
    it "should support to_a with sorted key-value pairs" do
      ary = @list.to_a
      ary.should == ary.sort{|a,b| a[0] <=> b[0] }
      ary.size.should == 1000
    end
    
    it "should have iterate pairs with #each" do
      c = []
      @list.each do |key, value|
        c << [key, value]
      end
			c.should have_at_least(10).items
      c[0..10].each do |a|
        a[0].should == a[1]  # key == value
      end
      c.should == c.sort{|a, b| a[0] <=> b[0] }  # sorted order
    end
    
  end
  
  
  describe "SimpleSkiplist#first_key [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(nil, :maxlevel => @maxlevel, :probability => @probability)
    end
    it "should return nil for empty skiplist" do
      @list.first_key.should == nil
    end
    it "should return key for non-empty skiplist" do
      @list.insert("b", "data1")
      @list.first_key.should == "b"
      @list.insert("c", "data2")
      @list.first_key.should == "b"
    end
  end
  
  
  describe "SimpleSkiplist#find_nearest [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(nil, :maxlevel => @maxlevel, :probability => @probability)
    end
    it "should find nil in empty skiplist" do
      @list.find_nearest("a").should == nil
      @list.find_nearest("").should == nil
      @list.find_nearest(nil).should == nil
    end
    it "should find exact value if it is present" do
      @list.insert("b", "B")
      @list.insert("f", "F")
      @list.find_nearest("b").should == "B"
      @list.find_nearest("f").should == "F"
    end
    it "should find nearest value or nil" do
      @list.insert("b", "B")
      @list.insert("f", "F")
      @list.find_nearest("a").should == nil
      @list.find_nearest("c").should == "B"
      @list.find_nearest("g").should == "F"
    end
    it "should always find empty-string key if nothing found" do
      @list.insert("",  "Empty")
      @list.insert("b", "B")
      @list.insert("f", "F")
      @list.find_nearest("a").should == "Empty"
      @list.find_nearest("c").should == "B"
      @list.find_nearest("g").should == "F"
    end
  end
end

def raw_list(list)
  list.marshal_dump[:raw_list]
end

