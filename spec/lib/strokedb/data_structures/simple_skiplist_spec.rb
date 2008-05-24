require File.dirname(__FILE__) + '/spec_helper'


describe "Skiplist serialization", :shared => true do
  it "should correctly load what it dumped" do
    dump1 = @list.dump
    newlist = @list.class.load(dump1)
    dump2 = newlist.dump
    dump1.should == dump2
    newlist.to_a.should == @list.to_a
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
      @list = SimpleSkiplist.new(:maxlevel => @maxlevel, :probability => @probability)
    end
  
  	it "should be empty" do
  		@list.should be_empty
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
      @list = SimpleSkiplist.new(:maxlevel => @maxlevel, :probability => @probability)
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
        r = @list.insert(k, k, i)
        r.object_id.should == @list.object_id
        r.should == @list
        
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


  describe "Deleting from skiplist" do
    before(:each) do
      @list = SimpleSkiplist.new
      @list.insert "1a", "a"
      @list.insert "1b", "b"
      @list.insert "1c", "c"
      @list.insert "1d", "d"
    end
    it "should store nil" do
      @list.insert("1b", nil)
      @list.search("1", "1", 3, 0, false, false).should == ["a", nil, "c"]
    end
    it "should delete item" do
      @list.delete("1b")
      @list.search("1", "1", 3, 0, false, false).should == ["a", "c", "d"]
    end
  end


  describe "Big skiplist [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(:maxlevel => @maxlevel, :probability => @probability)
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
  
  describe "SimpleSkiplist serialization [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @list = SimpleSkiplist.new(:maxlevel => @maxlevel)
      @arr = (1..1000).to_a.map{|a| a.to_s}.sort
    end
    it "should export data to_a correctly" do
      @arr.each{|e| @list.insert(e,e) }
      @list.to_a.should == @arr.map{|e| [e, e]}
    end
    it "should load data from_a correctly" do
      @list2 = @list.class.from_a(@arr.map{|e| [e, e]}, :maxlevel => @maxlevel)
      @list2.to_a.should == @arr.map{|e| [e, e]}
    end
  end
  
  describe "SimpleSkiplist#first_key [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @list = SimpleSkiplist.new(:maxlevel => @maxlevel, :probability => @probability)
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
      @list = SimpleSkiplist.new(:maxlevel => @maxlevel, :probability => @probability)
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
  
  describe "SimpleSkiplist#search [#{lang}]" do
    before(:each) do
      @list = SimpleSkiplist.new
      @keys = %w[ a aa ab b ba bb pfx1 pfx2 pfx3 x xx xy xyz ]
      @values = @keys.map{|v| v + " value"}
      @key_values = @keys.map{|v| [v, v]}
      @key_values.each do |k, v|
        @list.insert(k, v)
      end
    end
    
    it_should_behave_like "Skiplist serialization"
    
    it "should find all items" do
      search_should_yield(@key_values)
    end
    
    it "should find all items starting with a prefix" do
      search_should_yield(@key_values,          :start_key => "a")
      search_should_yield(@key_values[1..-1],   :start_key => "aa")
      search_should_yield(@key_values[2..-1],   :start_key => "ab")
      search_should_yield(@key_values[3..-1],   :start_key => "b")
      search_should_yield(@key_values[-1..-1],  :start_key => "xyz")
      search_should_yield(@key_values[6..-1],   :start_key => "pfx")
    end
    
    it "should not find any items if prefix not matched" do
      search_should_yield([],  :start_key => "middle")
      search_should_yield([],  :start_key => "__prefix")
      search_should_yield([],  :start_key => "zuffix")
      search_should_yield([],  :start_key => "pfx0")
    end
    
    it "should not find all items before the given end_key (inclusive)" do
      search_should_yield(@key_values,          :end_key => "xyz")
      search_should_yield(@key_values,          :end_key => "zuffix")
      search_should_yield(@key_values[0..-3],   :end_key => "xx")
      search_should_yield(@key_values[0..2],    :end_key => "a")
      search_should_yield(@key_values[0..1],    :end_key => "aa")
      search_should_yield(@key_values[0..5],    :end_key => "b")
    end
    
    it "should find items in a range" do
      search_should_yield(@key_values[1..5], :start_key => "aa",  :end_key => "bb")
      search_should_yield(@key_values[0..2], :start_key => "a",   :end_key => "a")
      search_should_yield(@key_values[3..5], :start_key => "b",   :end_key => "b")
      search_should_yield(@key_values[6..8], :start_key => "pfx", :end_key => "pfx")
      search_should_yield(@key_values[0..5], :start_key => "a",   :end_key => "b")
      search_should_yield(@key_values[1..5], :start_key => "aa",  :end_key => "b")
    end
    
    it "should not find items in an invalid range" do
      search_should_yield([], :start_key => "b",   :end_key => "a")
      search_should_yield([], :start_key => "z",   :end_key => "a")
      search_should_yield([], :start_key => "_",   :end_key => "b")
      search_should_yield([], :start_key => "ab1", :end_key => "b")
    end

    it "should search in a reverse order" do
      r = search_with_options(@list, :reverse => true, :with_keys => true)
      r.should == @key_values.reverse
    end
    
    it "should find a range in a reversed order" do
      r = search_with_options(@list, :start_key => "ab", :end_key => "aa", :reverse => true)
      r.should == %w[ab aa]
      r = search_with_options(@list, :start_key => "b", :end_key => "aa", :reverse => true)
      r.should == %w[aa ab b ba bb].reverse
      r = search_with_options(@list, :start_key => "ba", :end_key => "a", :reverse => true)
      r.should == %w[a aa ab b ba].reverse
    end

    it "should find a value in a reversed order" do
      r = search_with_options(@list, :start_key => "a", :end_key => "a", :reverse => true)
      r.should == %w[ab aa a]
      r = search_with_options(@list, :start_key => "xyz", :end_key => "xyz", :reverse => true)
      r.should == %w[xyz]
    end
    
      
    def search_should_yield(results, os = {})
      # TODO: added reverse cases
      list = @list
      
      os = os.merge(:with_keys => true)
      r = search_with_options(list, os)
      r.should == results
      search_should_use_offsets_and_limits(list, os, r)
      
      os = os.merge(:with_keys => nil)
      r = search_with_options(list, os)
      r.should == results.map{|k,v| v}
      search_should_use_offsets_and_limits(list, os, r)
    end
    
    def search_should_use_offsets_and_limits(list, os, r1)
      
      offsets = [-1000, -1, 0, 1, 2, 3, 4, 1000]
      limits  = [-1000, -1, 0, 1, 2, 3, 4, 1000]
      
      offsets.each do |off|
        limits.each do |lim|
          r2 = search_with_options(list, os.merge(:offset => off, :limit => lim))
          r2.should == (r1[off < 0 ? 0 : off, lim < 0 ? 0 : lim] || [])
        end
      end
    end
        
    def search_with_options(list, os = {})
      #puts "OPTIONS: #{os.inspect}"
      r = list.search(os[:start_key], os[:end_key], os[:limit], os[:offset], os[:reverse], os[:with_keys])
      #puts "R: #{r.inspect}"
      r 
    end

  end
end

def raw_list(list)
  list.marshal_dump[:raw_list]
end

