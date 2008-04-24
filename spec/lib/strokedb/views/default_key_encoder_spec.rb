require File.dirname(__FILE__) + '/spec_helper'

describe DefaultKeyEncoder do
  
  before(:each) do
    @items = [
      nil,
      false,
      true,
      -0x66666,
      -0x66666 + 0.1,
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
      :ab,
      :abb,
      "b",
      :bb
    ]
    
    @arrays = [
      ["a"],
      [:a, :b],
      [:b],
      ["b", "b"]  
    ]
  end
  
  it "should correctly collate JSON types" do
    (@items + @arrays).each_with_index do |a, index|
      (@items + @arrays)[index + 1, @items.size].each do |b|
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
    pending "not implemented (look for Zed Show's prefix encoder)"
    
    arr = ["a", "b"]
    arr2 = DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(arr))
    arr2.should == arr
  end
end


