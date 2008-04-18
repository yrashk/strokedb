require File.dirname(__FILE__) + '/spec_helper'

describe "String UUID" do
  it "should have specific format" do
    1000.times do 
      uuid = Util::random_uuid
      uuid.should =~ /^#{UUID_RE}$/
    end
  end
  it "should be converted to raw string" do
    "00000000-0000-0000-0000-000000000010".to_raw_uuid.should == "\x00"*15 + "\x10"
    "ffffffff-ffff-ffff-ffff-ffffffffffff".to_raw_uuid.should == "\xff"*16
    "00000000-0000-0000-ffff-ffffffffffff".to_raw_uuid.should == "\x00"*8 + "\xff"*8
  end
end

describe "Raw UUID" do
  it "should have specific format" do
    1000.times do 
      uuid = Util::random_uuid_raw
      uuid.should be_an_instance_of(String)
      uuid.size.should == 16 
    end
  end
  it "should be converted to formatted string" do
    ("\x00"*15 + "\x10").to_formatted_uuid.should == "00000000-0000-0000-0000-000000000010"
    ("\xff"*16).to_formatted_uuid.should          == "ffffffff-ffff-ffff-ffff-ffffffffffff"
    ("\x00"*8 + "\xff"*8).to_formatted_uuid.should      == "00000000-0000-0000-ffff-ffffffffffff"
  end
end

describe "UUID String conversion" do
  it "should convert raw to formatted and back" do
    1000.times do
      raw = Util::random_uuid_raw
      raw.to_formatted_uuid.to_raw_uuid.should == raw
    end
  end
  it "should convert formatted to raw and back" do
    1000.times do
      fmt = Util::random_uuid
      fmt.to_raw_uuid.to_formatted_uuid.should == fmt
    end
  end
end

