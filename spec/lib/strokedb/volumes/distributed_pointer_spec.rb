require File.dirname(__FILE__) + '/spec_helper'

describe "DistributedPointer" do
  it "should be packed correctly" do
    dp = DistributedPointer.new("\xff"*16, 1)
    dp.pack.should == "\xff"*16 + "\x01\x00\x00\x00"
  end
  
  it "should be unpacked correctly" do
    dp = DistributedPointer.unpack("\xff"*16 + "\x05\x00\x00\x00")
    dp.volume_uuid.should == "\xff"*16
    dp.offset.should == 5
  end
end
