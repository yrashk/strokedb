require File.dirname(__FILE__) + '/spec_helper'

describe "FileChunkStorage" do

  before(:each) do
    @path = 'test/storages/file_chunk_storage_spec'
    @storage = FileChunkStorage.new(@path)
    @storage.clear!

    @chunk = Chunk.new(99)
    @chunk.insert('34b030ab-03a5-a08a-4d97-a7b27daf0897', {'a' => 1, 'b' => 2})
  end

  it "should be empty when created" do
    # TODO
  end

  # it "should save something" do
  #   @storage.save! @chunk
  #   @storage.each do |chunk|
  #     chunk.should be_eql(@chunk)
  #   end
  # end

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

  after(:each) do
    # Keep files for investigation
    # FileUtils.rm_rf @path
  end

end

