require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "MemoryChunkStorage" do

  before(:each) do
    @storage = MemoryChunkStorage.new

    @chunk = Chunk.new(99)
    @chunk.insert('34b030ab-03a5-a08a-4d97-a7b27daf0897', {'a' => 1, 'b' => 2})
  end

  it_should_behave_like "ChunkStorage"


end

