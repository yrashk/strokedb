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
      1000000000000000000000000000000000,
      1000000000000000000000000000000000.01,
      1000000000000000000000000000000000.011,
      "",
      "0",
      "1",
      "10",
      "2",
      "a",
      :ab,
      :abb,
      "b",
      :bb,
      ["a"],
      [:a, :b],
      [:b],
      ["b", "b"]
    ]
  end
  
  it "should correctly collate JSON types" do
    @items.each_with_index do |a, index|
      @items[index + 1, @items.size].each do |b|
        String.should === DefaultKeyEncoder.encode(a)
        String.should === DefaultKeyEncoder.encode(b)
        DefaultKeyEncoder.encode(a).should < DefaultKeyEncoder.encode(b)
      end
    end
  end
  
  it "should correctly decode encoded JSON keys" do 
    @items.each_with_index do |a, index|
      @items[index + 1, @items.size].each do |b|
        DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(a)).should == a
        DefaultKeyEncoder.decode(DefaultKeyEncoder.encode(b)).should == b
      end
    end
  end
  
end


