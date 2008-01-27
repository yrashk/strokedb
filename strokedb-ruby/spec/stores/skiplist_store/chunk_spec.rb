require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Empty Chunk" do
  before(:each) do
    @it = Chunk.new(3)
  end
  
  it { @it.size.should       == 0 }
  it { @it.cut_level.should  == 3 }
  it { @it.uuid.should       == nil }
  it { @it.next_chunk.should == nil }
  
  it "should be serialized" do
    @it.to_raw.should == {"cut_level"=>3, "uuid"=>nil, "next_uuid"=>nil, "nodes"=>[]}
  end
end


describe "Chunk (cut)" do
  
  before(:each) do
    @chunk = Chunk.new(4)
    @chunk.insert('500', 'V', 2)
  end
  
  it "should find single value" do
    @chunk.find('500').should == 'V'
    @chunk.size.should == 1
    @chunk.uuid.should == '500'
  end
  it "should insert low level into the start" do
    a, b = @chunk.insert('200', 'V', 1)
    a.should == @chunk
    b.should be_nil
    a.size.should == 2
    a.uuid.should == '500'
  end
  it "should insert cut level into the start" do
    a, b = @chunk.insert('200', 'V', 4)
    a.should == @chunk
    b.should be_nil
    a.size.should == 2
    a.uuid.should == '500'
  end
  it "should set uuid for next chunk" do
    a, b = @chunk.insert('600', 'W', 4)
    a.should == @chunk
    a.size.should == 1
    a.uuid.should == '500'
    a.find('500').should == 'V'
    
    b.should_not be_nil
    b.size.should == 1
    b.find('600').should == 'W'
    b.uuid.should == '600'
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
