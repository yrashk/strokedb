require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "FileChunkStorage" do

  before(:each) do
    @path = 'test/storages/file_chunk_storage_spec'
    @storage = FileChunkStorage.new(@path)
    @storage.clear!

    @chunk = Chunk.new(99)
    @chunk.insert('34b030ab-03a5-a08a-4d97-a7b27daf0897', {'a' => 1, 'b' => 2})
  end

  it_should_behave_like "ChunkStorage"

  after(:each) do
    # Keep files for investigation
    # FileUtils.rm_rf @path
  end

end

