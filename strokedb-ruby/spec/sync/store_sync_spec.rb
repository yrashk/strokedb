require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

[SkiplistStore].each do |store|
  describe "#{store} that.sync!s documents in" do
    
    before(:each) do
      StrokeDB::Config.build :default => true, :store => :skiplist, :base_path => File.dirname(__FILE__) + '/../../test/storages/store_sync'
      @store = StrokeDB.default_store
      another_cfg = StrokeDB::Config.build :base_path => File.dirname(__FILE__) + '/../../test/storages/store_sync_another'
      @another_store = another_cfg.stores[:default]
    end
    
    after(:each) do
      FileUtils.rm_rf File.dirname(__FILE__) + '/../../test/storages/store_sync'
      FileUtils.rm_rf File.dirname(__FILE__) + '/../../test/storages/store_another'
    end
    
    it "should add document that does not yet exist" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      sync_rep = @store.sync!(doc.__versions__.all.reverse)
      @store.find(doc.uuid,doc.__previous_version__).should == doc.__versions__.previous
      @store.find(doc.uuid,doc.__version__).should == doc
      @store.find(doc.uuid).should == doc
      @store.find(doc.uuid).__versions__.all.should_not include(nil)
      sync_rep.conflicts.should be_empty
      sync_rep.fast_forwarded_documents.should be_empty
      sync_rep.added_documents.should == [doc]
    end
    
    it "should fast-forward document if applicable" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      sync_rep = @store.sync!(doc.__versions__.all.reverse)
      doc_at_store = @store.find(doc.uuid)
      sync_rep.conflicts.should be_empty
      sync_rep.added_documents.should == [doc_at_store]
      sync_rep.fast_forwarded_documents.should be_empty
      doc_at_store.ok = true
      doc_at_store.save!
      another_sync_rep = @another_store.sync!(doc_at_store.__versions__.all.reverse)
      doc = @another_store.find(doc_at_store.uuid)
      doc.should == doc_at_store
      another_sync_rep.conflicts.should be_empty
      another_sync_rep.added_documents.should be_empty
      another_sync_rep.fast_forwarded_documents.should == [doc]
    end
    
    it "should create non-matching report if applicable" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      adoc = Document.create!(:uuid => doc.uuid)
      sync_rep = @store.sync!(doc.__versions__.all.reverse)
      sync_rep.conflicts.should be_empty
      sync_rep.non_matching_documents.should == [adoc]
      sync_rep.added_documents.should be_empty
      sync_rep.fast_forwarded_documents.should be_empty
    end
    
    it "should do nothing if everything is up-to-date" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      sync_rep = @store.sync!(doc.__versions__.all.reverse)
      sync_rep.conflicts.should be_empty
      sync_rep.non_matching_documents.should be_empty
      sync_rep.added_documents.should_not be_empty
      sync_rep.fast_forwarded_documents.should be_empty
      doc_at_store = @store.find(doc.uuid)
      another_sync_rep = @another_store.sync!(doc_at_store.__versions__.all.reverse)
      @another_store.find(doc_at_store.uuid).should == doc_at_store
      another_sync_rep.conflicts.should be_empty
      another_sync_rep.non_matching_documents.should be_empty
      another_sync_rep.added_documents.should be_empty
      another_sync_rep.fast_forwarded_documents.should be_empty
    end
    
    it "should create SynchronizationConflict if applicable" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      @store.sync!(doc.__versions__.all.reverse)
      doc_at_store = @store.find(doc.uuid)
      doc_at_store.ok = true
      doc_at_store.save!
      doc.ok = false
      doc.save!
      another_sync_rep = @another_store.sync!(doc_at_store.__versions__.all.reverse)
      another_sync_rep.non_matching_documents.should be_empty
      another_sync_rep.added_documents.should be_empty
      another_sync_rep.fast_forwarded_documents.should be_empty
      another_sync_rep.conflicts.should_not be_empty
      conflict = another_sync_rep.conflicts.first
      conflict.rev1[1].should == doc_at_store.__version__
      conflict.rev2[1].should == doc.__version__
    end
    
    it "should update timestamp prior to.sync! if it is specified" do
      original_timestamp = @store.timestamp
      @store.sync!([],100)
      @store.timestamp.counter.should >= 100
      @store.timestamp.should_not == original_timestamp
      original_timestamp = @store.timestamp
      @store.sync!([],LTS.new(200))
      @store.timestamp.counter.should >= 200
      @store.timestamp.should_not == original_timestamp
    end
        
  end
end