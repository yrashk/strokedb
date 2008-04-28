require File.dirname(__FILE__) + '/spec_helper'

describe DefaultKeyEncoder do
  
  before(:each) do
    @items = [
      nil,
      false,
      true,
      -66666,
      -66666 + 0.1,
      -0.0000000001,
      0,
      0.000000001,
      1,
      1.1,
      2,
      10,
      20,
      100,
      1000000000,
      1000000000.01,
      1000000000.011,
      "",
      "0",
      "1",
      "10",
      "2",
      "a",
      ["a", "b"],
      :ab,
      :abb,
      "b",
      ["b", "b"],  
      :bb
    ]
    
  end
  
  it "should correctly collate JSON types" do
    @items.each_with_index do |a, index|
      @items[index + 1, @items.size].each do |b|
        String.should === DefaultKeyEncoder.encode(a)
        String.should === DefaultKeyEncoder.encode(b)
        ae = DefaultKeyEncoder.encode(a)
        be = DefaultKeyEncoder.encode(b)
        unless ae < be 
          p [a, b]
          p [ae, be]
        end
        ae.should < be
      end
    end
  end
  
  it "should correctly decode encoded JSON keys" do 
    delta = 0.0000001
    @items.each_with_index do |a, index|
      @items[index + 1, @items.size].each do |b|
        a2 = DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(a))
        b2 = DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(b))
        if Float === a 
          a2.should > a - delta
          a2.should < a + delta
        elsif Symbol === a
          a.to_s.should == a2 
        else
          a2.should == a
        end
        if Float === b 
          b2.should > b - delta
          b2.should < b + delta
        elsif Symbol === b
          b.to_s.should == b2 
        else
          b2.should == b
        end
      end
    end
  end
  
  it "should decode arrays" do
    arr = ["a", "b"]
    arr2 = DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(arr))
    arr2.should == arr
  end
  
  it "should encode/decode string with spaces gracefully" do
    DefaultKeyEncoder.decode(DefaultKeyEncoder.encode("a b")).should == ["a", "b"]
    DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(["1", "a b"])).should == ["1", "a", "b"]
    DefaultKeyEncoder.decode(DefaultKeyEncoder.encode([1,"a D"])).should == [1, "a", "D"]
  end
  
  it "should raise an error if trying to encode Hash" do
    lambda do
      DefaultKeyEncoder.encode({})
    end.should raise_error(StandardError)
  end
  
  it "should encode Document and decode as a uuid" do
    setup_default_store
    doc = Document.new
    encoded_key = DefaultKeyEncoder.encode(doc)
    encoded_key.should == "@#{doc.uuid}"
    DefaultKeyEncoder.decode(encoded_key).should == doc.uuid
  end
  
  it "should decode stuff without a known prefix as a string" do
    DefaultKeyEncoder.decode("string").should == "string"
  end

  it "should decode stuff with spaces without a known prefix as an array" do
    DefaultKeyEncoder.decode("it is a string").should == "it is a string".split
  end
  
  it "should encode and decode Time values" do
    times = [
        Time.now - 1000000,
        Time.now,
        Time.now,
        Time.now + 1000000
      ]
    
    strs = times.map {|t| DefaultKeyEncoder.encode(t) } 
    strs.should == strs.sort
    
    times2 = strs.map{|ts| DefaultKeyEncoder.decode(ts) }
    times2.zip(times) {|t2, t1| t2.should be_close(t1, 0.000002) }
  end
  
end


