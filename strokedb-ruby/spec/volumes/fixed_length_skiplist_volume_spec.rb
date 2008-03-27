require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

SimpleSkiplist.with_optimizations(OPTIMIZATIONS) do |lang|

  describe "Empty FixedLengthSkiplistVolume [#{lang}]" do
  
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @path = File.dirname(__FILE__) + '/../../test/storages/fixed_length_sl_volume'
      FileUtils.rm_rf @path
      @list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
    end
  
  	it "should be empty" do
  		@list.should be_empty
  	end
	
  	it "should find nil in a empty skiplist" do
  	  @list.find("x"*10).should == nil
    end
  
  end


  describe "Inserting in a skiplist [#{lang}]" do

    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @path = File.dirname(__FILE__) + '/../../test/storages/fixed_length_sl_volume'
      FileUtils.rm_rf @path
      @list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
    end

    it "should insert non-empty key" do
      @list.insert("x"*10, "4"*10, 1).should == @list
      @list.find("x"*10).should == "4"*10
      @list.find("y"*10).should be_nil
    end
  
    it "should correctly insert keys in an ascending level order" do
      1.upto(@maxlevel) do |i|
        k = "x#{i}".ljust(10,'0')
        @list.insert(k, k, i).should == @list
        @list.find(k).should == k
        @list.find("-"*10).should == nil
      end
      # repeat
      1.upto(@maxlevel) do |i|
        k = "x#{i}".ljust(10,'0')
        @list.find(k).should == k
      end
    end
  
    it "should correctly insert keys in a descending level order" do
      @maxlevel.downto(1) do |i|
        k = "x#{@maxlevel-i}".ljust(10,'0')
        @list.insert(k, k, i).should == @list
        @list.find(k).should == k
        @list.find("-"*10).should == nil
      end
      # repeat
      @maxlevel.downto(1) do |i|
        k = "x#{@maxlevel-i}".ljust(10,'0')
        @list.find(k).should == k
      end
    end  
  end


  describe "Big skiplist [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @path = File.dirname(__FILE__) + '/../../test/storages/fixed_length_sl_volume'
      FileUtils.rm_rf @path
      @list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 20, :value_length => 20)
      1000.times do 
        v = k = rand(2**64).to_s.rjust(20,'0')
        @list.insert(k, v)
      end
    end
  
  
    it "should support to_a with sorted key-value pairs" do
      ary = @list.to_a
      ary.should == ary.sort{|a,b| a[0] <=> b[0] }
      ary.size.should == 1000
    end
  end
  
  
  describe "FixedLengthSkiplistVolume#first_key [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @path = File.dirname(__FILE__) + '/../../test/storages/fixed_length_sl_volume'
      FileUtils.rm_rf @path
      @list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
    end
    it "should return nil for empty skiplist" do
      @list.first_key.should == nil
    end
    it "should return key for non-empty skiplist" do
      @list.insert("b"*10, "1"*10)
      @list.first_key.should == "b"*10
      @list.insert("c"*10, "2"*10)
      @list.first_key.should == "b"*10
    end
  end
  
  
  describe "FixedLengthSkiplistVolume#find_nearest [#{lang}]" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @path = File.dirname(__FILE__) + '/../../test/storages/fixed_length_sl_volume'
      FileUtils.rm_rf @path
      @list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
    end
    it "should find zero value in empty skiplist" do
      @list.find_nearest("a").should == "\x00"*10
      @list.find_nearest("").should == "\x00"*10
      @list.find_nearest(nil).should == "\x00"*10
    end
    it "should find exact value if it is present" do
      @list.insert("b"*10, "B"*10)
      @list.insert("f"*10, "F"*10)
      @list.find_nearest("b"*10).should == "B"*10
      @list.find_nearest("f"*10).should == "F"*10
    end
    it "should find nearest value or nil" do
      @list.insert("b"*10, "B"*10)
      @list.insert("f"*10, "F"*10)
      @list.find_nearest("a"*10).should == "\x00"*10
      @list.find_nearest("c"*10).should == "B"*10
      @list.find_nearest("g"*10).should == "F"*10
    end
    # it "should always find empty-string key if nothing found" do
    #   @list.insert("",  "Empty")
    #   @list.insert("b", "B")
    #   @list.insert("f", "F")
    #   @list.find_nearest("a").should == "Empty"
    #   @list.find_nearest("c").should == "B"
    #   @list.find_nearest("g").should == "F"
    # end
  end
  
  describe "Saved FixedLengthSkiplistVolume" do
    before(:each) do
      @maxlevel    = 8
      @probability = 0.5
      @path = File.dirname(__FILE__) + '/../../test/storages/fixed_length_sl_volume'
      FileUtils.rm_rf @path
      @list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
    end
    
    it "with actual data inside should be loaded properly" do
      @list.insert("A"*10,"B"*10)
      @list.close!
      @new_list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
      @new_list.find("A"*10).should == "B"*10
    end

    it "with no actual data inside should be loaded properly" do
      @list.close!
      @new_list = FixedLengthSkiplistVolume.new(:path => @path, :maxlevel => @maxlevel, :probability => @probability, :key_length => 10, :value_length => 10)
      @new_list.find("A"*10).should == nil
    end
    
  end
end

def raw_list(list)
  list.marshal_dump[:raw_list]
end

