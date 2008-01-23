require File.dirname(__FILE__) + '/spec_helper'

describe "Empty Chunk" do
  before(:each) do
    @it = Chunk.new(3)
  end
  
  it { @it.size.should == 0 }
  it { @it.cut_level.should == 3 }
  it { @it.uuid.should == nil }
  it { @it.next_chunk.should == nil }
  
  it "should be serialized" do
    @it.to_raw.should == {"cut_level"=>3, "uuid"=>nil, "next_uuid"=>nil, "nodes"=>[]}
  end
end

describe "Chunks" do
  
  before(:each) do
    head_chunk = Chunk.new(3)
    @docs_by_uuid = {}
    @all_chunks = {} # uuid => chunk
    20.times do |i|
      uuid = "K#{100+i}"
      doc = {:i => i, :text => "Text."}
      @docs_by_uuid[uuid] = doc
      a, b = head_chunk.insert(uuid, doc)
      head_chunk = b || a
      [a, b].each do |c|
        @all_chunks[c.uuid] = c if c
      end
    end
  end

  it "should be serialized well" do
    @all_chunks.each do |k,v|
      rawv = v.to_raw
      object = Chunk.from_raw(rawv)
      object.next_chunk = @all_chunks[rawv['next_uuid']]
      rawv.should == object.to_raw 
    end
  end
  
  it "should find stored data" do
    @docs_by_uuid.each do |uuid, doc|
      found = false
      @all_chunks.each do |cuuid, chunk|
        found = chunk.find(uuid, nil)
        break if found
      end
      found.should == doc
    end
  end
  
end
