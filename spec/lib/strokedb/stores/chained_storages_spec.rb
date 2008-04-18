require File.dirname(__FILE__) + '/spec_helper'

[ FileStorage, MemoryStorage ].each do |storage|
  describe "Chained chunk storage (#{storage})" do

    before(:each) do
      @path = TEMP_STORAGES + '/file_chunk_storage_spec'
      FileUtils.rm_rf @path
      @storage = storage.new(:path => @path)
      @storage.clear!
      @store = mock("Store")
      @document = Document.new(@store, 'a' => 1, 'b' => 2)
      
      @target_storage = storage.new(:path => "#{@path}_chained")
      @target_storage.clear!
      
      @target_storage1 = storage.new(:path => "#{@path}_chained_1")
      @target_storage1.clear!
      
      @counter = LTS.zero
    end
    
    after(:each) do
      @target_storage.close!
      @target_storage1.close!
    end

    it "should collect update to target store" do
      @storage.save!(@document,@counter)
      @storage.add_chained_storage!(@target_storage)
      @document1 = Document.new(@store, 'x' => 1, 'y' => 2)
      @storage.save!(@document1,@counter)
      @target_storage.should_receive(:save!).with(@document1,@counter,{},@storage)
      @storage.sync_chained_storage!(@target_storage)
      @storage.sync_chained_storage!(@target_storage)
    end
    
    
    it "should collect update to multiple target store" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save!(@document,@counter)
      @storage.add_chained_storage!(@target_storage1)
      @document1 = Document.new(@store, 'x' => 1, 'y' => 2)
      @storage.save!(@document1,@counter)
      @target_storage.should_receive(:save!).with(@document,@counter,{},@storage).ordered
      @target_storage.should_receive(:save!).with(@document1,@counter,{},@storage).ordered
      @target_storage1.should_receive(:save!).with(@document1,@counter,{},@storage)
      
      @storage.sync_chained_storage!(@target_storage)
      @storage.sync_chained_storage!(@target_storage1)
    end

    it "should collect update to multiple target store and send them at once" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save!(@document,@counter)
      @storage.add_chained_storage!(@target_storage1)
      @document1 = Document.new(@store,'x' => 1, 'y' => 2)
      @storage.save!(@document1,@counter)
      @target_storage.should_receive(:save!).with(@document,@counter,{},@storage).ordered
      @target_storage.should_receive(:save!).with(@document1,@counter,{},@storage).ordered
      @target_storage1.should_receive(:save!).with(@document1,@counter,{},@storage)
      
      @storage.sync_chained_storages!
    end

    it "should collect multiple update to target store" do
      @storage.save!(@document,@counter)
      @storage.add_chained_storage!(@target_storage)
      @document1 = Document.new(@store, 'x' => 1, 'y' => 2)
      @document2 = Document.new(@store, 'v' => 1, 'z' => 2)
      @storage.save!(@document1,@counter)
      @storage.save!(@document2,@counter)
      @target_storage.should_receive(:save!).with(@document1,@counter,{},@storage).ordered
      @target_storage.should_receive(:save!).with(@document2,@counter,{},@storage).ordered
      @storage.sync_chained_storage!(@target_storage)
    end
    
    it "should remove savings sucessfully (current outstanding savings are dropped and new savings are no longer collected)" do
      @storage.save!(@document,@counter)
      @storage.add_chained_storage!(@target_storage)
      @document1 = Document.new(@store,'x' => 1, 'y' => 2)
      @storage.remove_chained_storage!(@target_storage)
      @document2 = Document.new(@store,'v' => 1, 'z' => 2)
      @storage.save!(@document1,@counter)
      @storage.save!(@document2,@counter)
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
      @storage.save!(@document,@counter)
      @storage.sync_chained_storage!(@target_storage)
      @storage.should_not_receive(:save!).with(@document,@counter,{},@target_storage)
      @target_storage.sync_chained_storage!(@storage)
    end
    
    it "should let next storage to sync on sync_chained_storages! as well" do
      @storage.add_chained_storage!(@target_storage)
      @storage.save!(@document,@counter)
      @target_storage.should_receive(:sync_chained_storages!).once
      @storage.sync_chained_storages!
    end

  end
end
