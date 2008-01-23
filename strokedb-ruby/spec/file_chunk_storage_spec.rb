require File.dirname(__FILE__) + '/spec_helper'

describe "FileChunkStorage" do

  before(:each) do
    @path = '__test_file_chunk_store'
    FileUtils.rm_rf @path
    @storage = FileChunkStorage.new(@path)
    @chunk = mock("Chunk")
    @chunk.stub!(:to_raw).and_return({'a' => 1, 'b' => 2})
    @chunk.stub!(:uuid).and_return('34b030ab-03a5-a08a-4d97-a7b27daf0897')
    Chunk.should_receive(:from_raw).any_number_of_times.and_return {|c| c && c['a'] == 1 ? @chunk : fail("Unknown raw chunk: #{c.inspect}") }
  end
  
  it "should be empty when created" do
    @storage.each do |chunk|
      fail("Storage should be empty, but a chunk is found: #{chunk}")
    end
  end
  
  it "should save something" do
    @storage.save! @chunk
    @storage.each do |chunk|
      chunk.should == @chunk
    end
  end
  
  after(:each) do
    FileUtils.rm_rf @path
  end

end


