require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "ChunkStorage", :shared => true do

  it "should find a chunk by UUID" do
    @storage.find(@chunk.uuid).should be_nil
    @storage.save! @chunk
    @storage.find(@chunk.uuid).should be_eql(@chunk)
    @storage.find(@chunk.uuid).to_raw.should == @chunk.to_raw
  end

  it "should find a MASTER chunk" do
    @storage.find('MASTER').should be_nil
    c = Chunk.new(99)
    raw_doc = {'ref' => 'chunk'}
    c.uuid = 'MASTER'
    c.insert('some-uuid', raw_doc)
    @storage.save! c
    @storage.find('MASTER').find('some-uuid').should == raw_doc
  end



end

