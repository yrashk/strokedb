require File.dirname(__FILE__) + '/spec_helper'

STORAGES = [MemoryChunkStorage, FileChunkStorage]

STORAGES.each do |storage|
  describe "Chained chunk storage" do

    before(:each) do
      @path = 'test/storages/file_chunk_storage_spec'
      @storage = storage.new(@path)

      @chunk = Chunk.new(99)
      @chunk.insert('34b030ab-03a5-a08a-4d97-a7b27daf0897', {'a' => 1, 'b' => 2})
    end

    it "should collect update to target store" do
      target_storage = mock("Target store")
      @storage.save! @chunk
      @storage.add_replica!(target_storage)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.save! @chunk1
      target_storage.should_receive(:save!).with(@chunk1)
      @storage.replicate!(target_storage)
    end
    
    it "should collect update to multiple target store" do
      target_storage = mock("Target store")
      target_storage1 = mock("Target store 1")
      @storage.add_replica!(target_storage)
      @storage.save! @chunk
      @storage.add_replica!(target_storage1)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.save! @chunk1
      target_storage.should_receive(:save!).with(@chunk).ordered
      target_storage.should_receive(:save!).with(@chunk1).ordered
      target_storage1.should_receive(:save!).with(@chunk1)
      
      @storage.replicate!(target_storage)
      @storage.replicate!(target_storage1)
    end

    it "should collect update to multiple target store and send them at once" do
      target_storage = mock("Target store")
      target_storage1 = mock("Target store 1")
      @storage.add_replica!(target_storage)
      @storage.save! @chunk
      @storage.add_replica!(target_storage1)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.save! @chunk1
      target_storage.should_receive(:save!).with(@chunk).ordered
      target_storage.should_receive(:save!).with(@chunk1).ordered
      target_storage1.should_receive(:save!).with(@chunk1)
      
      @storage.replicate!
    end

    it "should collect multiple update to target store" do
      target_storage = mock("Target store")
      @storage.save! @chunk
      @storage.add_replica!(target_storage)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @chunk2 = Chunk.new(99)
      @chunk2.insert('34b030ax-03a5-a08a-4d97-a7b27daf0897', {'v' => 1, 'z' => 2})
      @storage.save! @chunk1
      @storage.save! @chunk2
      target_storage.should_receive(:save!).with(@chunk1).ordered
      target_storage.should_receive(:save!).with(@chunk2).ordered
      @storage.replicate!(target_storage)
    end
    
    it "should remove replications sucessfully (current outstanding replicas are dropped and new replicas are no longer collected)" do
      target_storage = mock("Target store")
      @storage.save! @chunk
      @storage.add_replica!(target_storage)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.remove_replica!(target_storage)
      @chunk2 = Chunk.new(99)
      @chunk2.insert('34b030ax-03a5-a08a-4d97-a7b27daf0897', {'v' => 1, 'z' => 2})
      @storage.save! @chunk1
      @storage.save! @chunk2
      @storage.replicate!(target_storage)
    end

  end
end
