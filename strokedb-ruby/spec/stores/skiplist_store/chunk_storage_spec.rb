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
 
describe "ChunkStorage with authoritative source" do
  
  before(:each) do
    @authoritative_source = mock("authoritative source")
    @storage = ChunkStorage.new
    @storage.authoritative_source = @authoritative_source
  end

  it "should call authoritative source's #find if chunk was not found" do
    @storage.should_receive(:chunk_path).with('blablabla').and_return('blablabla')
    @storage.should_receive(:read).with('blablabla').and_return(nil)
    
    result = mock("search result")
    @authoritative_source.should_receive(:find).with('blablabla').and_return(result)
    @storage.should_receive(:save!).with(result,@authoritative_source)
    @storage.find('blablabla').should == result
  end
  
end
