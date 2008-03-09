require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

[SkiplistStore].each do |store|
  describe "#{store} that.sync!s documents in" do
    
    before(:all) do
      StrokeDB::Config.build :default => true, :store => :skiplist
      @store = StrokeDB.default_store
      another_cfg = StrokeDB::Config.build
      @another_store = another_cfg.stores[:default]
    end
    
    it "should add document that does not yet exist" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      @store.sync!(doc.__versions__.all.reverse)
      @store.find(doc.uuid,doc.__previous_version__).should == doc.__versions__.previous
      @store.find(doc.uuid,doc.__version__).should == doc
      @store.find(doc.uuid).should == doc
      @store.find(doc.uuid).__versions__.all.should_not include(nil)
    end
    
    it "should fast-forward document if applicable" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      @store.sync!(doc.__versions__.all.reverse)
      doc_at_store = @store.find(doc.uuid)
      doc_at_store.ok = true
      doc_at_store.save!
      @another_store.sync!(doc_at_store.__versions__.all.reverse)
      @another_store.find(doc_at_store.uuid).should == doc_at_store
    end
    
    it "should raise NonMatchingDocumentCondition if applicable" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      adoc = Document.create!(:uuid => doc.uuid)
      lambda { @store.sync!(doc.__versions__.all.reverse) }.should raise_error(NonMatchingDocumentCondition)
    end
    
    it "should do nothing if everything is up-to-date" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      @store.sync!(doc.__versions__.all.reverse)
      doc_at_store = @store.find(doc.uuid)
      @another_store.sync!(doc_at_store.__versions__.all.reverse)
      @another_store.find(doc_at_store.uuid).should == doc_at_store
    end
    
    it "should raise ConflictCondition if applicable" do
      doc = Document.create!(@another_store, :hello => 'world')
      doc.test = 'passed'
      doc.save!
      @store.sync!(doc.__versions__.all.reverse)
      doc_at_store = @store.find(doc.uuid)
      doc_at_store.ok = true
      doc_at_store.save!
      doc.ok = false
      doc.save!
      lambda { @another_store.sync!(doc_at_store.__versions__.all.reverse) }.should raise_error(ConflictCondition)
      begin
        @another_store.sync!(doc_at_store.__versions__.all.reverse)
      rescue ConflictCondition
        $!.rev1[1].should == doc_at_store.__version__
        $!.rev2[1].should == doc.__version__
      end
    end
    
    it "should update timestamp prior to.sync! if it is specified" do
      original_timestamp = @store.lamport_timestamp
      @store.sync!([],100)
      @store.lamport_timestamp.counter.should == 100
    end
    
    it "should not update timestamp prior to.sync! if it is not specified" do
      original_timestamp = @store.lamport_timestamp
      @store.sync!([])
      @store.lamport_timestamp.counter.should == original_timestamp.counter
    end
    
  end
end