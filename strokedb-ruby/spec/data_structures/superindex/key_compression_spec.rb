require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe InvertedList::Node, "key compression" do
  before(:each) do
    @node = InvertedList::Node.new(1, '', '')
  end
  it "should compress key with 0-length prefix" do
    @node.compress_key('a',     '').should    == [0, 'a']
    @node.compress_key('a',     'b').should   == [0, 'a']
    @node.compress_key('a',     'bc').should  == [0, 'a']
    @node.compress_key('a',     'bcd').should == [0, 'a']
    @node.compress_key('a',     'b').should   == [0, 'a']
    @node.compress_key('ab',    'bc').should  == [0, 'ab']
    @node.compress_key('acd',   'bcd').should == [0, 'acd']
    @node.compress_key('abcd',  'bcd').should == [0, 'abcd']
  end
  it "should compress key with 1-length prefix" do
    @node.compress_key('a',     'ab').should   == [1, '']
    @node.compress_key('a',     'abc').should  == [1, '']
    @node.compress_key('a',     'abcd').should == [1, '']
    @node.compress_key('a',     'ab').should   == [1, '']
    @node.compress_key('ac',    'abc').should  == [1, 'c']
    @node.compress_key('acd',   'abcd').should == [1, 'cd']
    @node.compress_key('acde',  'abcd').should == [1, 'cde']
  end
  it "should compress key with various length prefices" do
    @node.compress_key('ab',     'ab').should   == [2, '']
    @node.compress_key('ab',     'abc').should  == [2, '']
    @node.compress_key('ab',     'abcd').should == [2, '']
    @node.compress_key('ab',     'ab').should   == [2, '']
    @node.compress_key('ab',     'abc').should  == [2, '']
    @node.compress_key('abcd',   'abc').should  == [3, 'd']
    @node.compress_key('abcd',   'abcd').should == [4, '']
  end
end

describe InvertedList::Node, "key decompression" do
  before(:each) do
    @node = InvertedList::Node.new(1, '', '')
    @keys_bases = %w[
      a    a
      a    ab
      ab   a
      ab   ab
      b    a
      b    ab
      a    b
      ab   b
      a    abc
      a    abcd
      ab   abc
      abc  abc
      abcd abc
      abcd ab
      abcd a
    ]
  end
  
  it "should compress/decompress against empty base" do
    %w[a ab abc abcd].each do |k|
      @node.compress_key(k, '').should == [0, k]
      @node.decompress_key([0, k], '').should == k
    end
  end
  
  it "should compress/decompress various key-base pairs" do
    (@keys_bases.size/2).times do |i|
      k = @keys_bases[2*i]
      b = @keys_bases[2*i + 1]
      c = @node.compress_key(k, b)
      @node.decompress_key(c, b).should == k
    end
  end
end

describe InvertedList::Node, "key spaceship (comparison) operator" do
  before(:each) do
    @node = InvertedList::Node.new(1, '', '')
  end
  
  it "should compare suffices with zero offset" do
    @node.key_spaceship("a", [0, ""]).should     == ("a" <=> "")
    @node.key_spaceship("a", [0, "b"]).should    == ("a" <=> "b")
    @node.key_spaceship("a", [0, "ab"]).should   == ("a" <=> "ab")
    @node.key_spaceship("a", [0, "abc"]).should  == ("a" <=> "abc")
  end
  
  it "should compare suffices with offset 1" do
    @node.key_spaceship("a",  [1, "a"]).should    == (""  <=> "a")
    @node.key_spaceship("za", [1, "b"]).should    == ("a" <=> "b")
    @node.key_spaceship("aa", [1, "ab"]).should   == ("a" <=> "ab")
    @node.key_spaceship("za", [1, "abc"]).should  == ("a" <=> "abc")
    
    @node.key_spaceship("aab", [1, "a"]).should    == ("ab" <=> "a")
    @node.key_spaceship("zab", [1, "b"]).should    == ("ab" <=> "b")
    @node.key_spaceship("aab", [1, "ab"]).should   == ("ab" <=> "ab")
    @node.key_spaceship("zab", [1, "abc"]).should  == ("ab" <=> "abc")
  end
end
