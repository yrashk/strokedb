require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

ChunkStorage.subclasses.map{|e| e.constantize}.each do |storage|
  describe "Chained chunk storage" do

    before(:each) do
      @path = 'test/storages/file_chunk_storage_spec'
      @storage = storage.new(:path => @path)

      @chunk = Chunk.new(99)
      @chunk.insert('34b030ab-03a5-a08a-4d97-a7b27daf0897', {'a' => 1, 'b' => 2})
      
      @target_storage = storage.new(:path => "#{@path}_chained")
      @target_storage.clear!
      
      @target_storage1 = storage.new(:path => "#{@path}_chained_1")
      @target_storage1.clear!
      
    end

    it "should collect update to target store" do
      @storage.save! @chunk
      @storage.add_chained_storage!(@target_storage)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.save! @chunk1
      @target_storage.should_receive(:save!).with(@chunk1,@storage)
      @storage.sync_chained_storage!(@target_storage)
      @storage.sync_chained_storage!(@target_storage)
    end
    
    
    it "should collect update to multiple target store" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save! @chunk
      @storage.add_chained_storage!(@target_storage1)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.save! @chunk1
      @target_storage.should_receive(:save!).with(@chunk,@storage).ordered
      @target_storage.should_receive(:save!).with(@chunk1,@storage).ordered
      @target_storage1.should_receive(:save!).with(@chunk1,@storage)
      
      @storage.sync_chained_storage!(@target_storage)
      @storage.sync_chained_storage!(@target_storage1)
    end

    it "should collect update to multiple target store and send them at once" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save! @chunk
      @storage.add_chained_storage!(@target_storage1)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.save! @chunk1
      @target_storage.should_receive(:save!).with(@chunk,@storage).ordered
      @target_storage.should_receive(:save!).with(@chunk1,@storage).ordered
      @target_storage1.should_receive(:save!).with(@chunk1,@storage)
      
      @storage.sync_chained_storages!
    end

    it "should collect multiple update to target store" do
      @storage.save! @chunk
      @storage.add_chained_storage!(@target_storage)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @chunk2 = Chunk.new(99)
      @chunk2.insert('34b030ax-03a5-a08a-4d97-a7b27daf0897', {'v' => 1, 'z' => 2})
      @storage.save! @chunk1
      @storage.save! @chunk2
      @target_storage.should_receive(:save!).with(@chunk1,@storage).ordered
      @target_storage.should_receive(:save!).with(@chunk2,@storage).ordered
      @storage.sync_chained_storage!(@target_storage)
    end
    
    it "should remove savings sucessfully (current outstanding savings are dropped and new savings are no longer collected)" do
      @storage.save! @chunk
      @storage.add_chained_storage!(@target_storage)
      @chunk1 = Chunk.new(99)
      @chunk1.insert('34b030ac-03a5-a08a-4d97-a7b27daf0897', {'x' => 1, 'y' => 2})
      @storage.remove_chained_storage!(@target_storage)
      @chunk2 = Chunk.new(99)
      @chunk2.insert('34b030ax-03a5-a08a-4d97-a7b27daf0897', {'v' => 1, 'z' => 2})
      @storage.save! @chunk1
      @storage.save! @chunk2
      @storage.sync_chained_storage!(@target_storage)
    end
    
    it "should add reverse chaining to target storage when adding chained storage" do
      @target_storage.should_receive(:add_chained_storage!).with(@storage)
      @storage.add_chained_storage!(@target_storage)
    end

    it "should remove reverse chaining from target storage when removing chained storage" do
      @target_storage.should_receive(:remove_chained_storage!).with(@storage)
      @storage.add_chained_storage!(@target_storage)
      @storage.remove_chained_storage!(@target_storage)
    end
    
    it "should not collect savings for target store if these saving where originally from the target store" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save! @chunk
      @storage.sync_chained_storage!(@target_storage)
      @storage.should_not_receive(:save!).with(@chunk)
      @target_storage.sync_chained_storage!(@storage)
    end
    
    it "should let next storage to sync on sync_chained_storages! as well" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save! @chunk
      @target_storage.should_receive(:sync_chained_storages!).once
      @storage.sync_chained_storages!
    end

  end
end
