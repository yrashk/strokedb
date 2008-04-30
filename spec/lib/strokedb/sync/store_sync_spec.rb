require File.dirname(__FILE__) + '/spec_helper'

describe "Store that syncs documents in" do

  before(:each) do
    FileUtils.rm_rf TEMP_STORAGES + '/store_sync'
    FileUtils.rm_rf TEMP_STORAGES + '/store_sync_another'
    StrokeDB::Config.build :default => true, :base_path => TEMP_STORAGES + '/store_sync'
    @store = StrokeDB.default_store
    another_cfg = StrokeDB::Config.build :base_path => TEMP_STORAGES + '/store_sync_another'
    @another_store = another_cfg.stores[:default]
  end

  after(:each) do
    @store.stop_autosync!
    @another_store.stop_autosync!
    FileUtils.rm_rf TEMP_STORAGES + '/store_sync'
    FileUtils.rm_rf TEMP_STORAGES + '/store_sync_another'
  end

  it "should add document that does not yet exist" do
    doc = Document.create!(@another_store, :hello => 'world')
    doc.test = 'passed'
    doc.save!
    sync_rep = @store.sync!(doc.versions.all.reverse)
    @store.find(doc.uuid,doc.previous_version).should == doc.versions.previous
    @store.find(doc.uuid,doc.version).should == doc
    @store.find(doc.uuid).should == doc
    @store.find(doc.uuid).versions.all.should_not include(nil)
    sync_rep.conflicts.should be_empty
    sync_rep.fast_forwarded_documents.should be_empty
    sync_rep.added_documents.should == [doc]
  end

  it "should fast-forward document if applicable" do
    doc = Document.create!(@another_store, :hello => 'world')
    doc.test = 'passed'
    doc.save!
    sync_rep = @store.sync!(doc.versions.all.reverse)
    doc_at_store = @store.find(doc.uuid)
    sync_rep.conflicts.should be_empty
    sync_rep.added_documents.should == [doc_at_store]
    sync_rep.fast_forwarded_documents.should be_empty
    doc_at_store.ok = true
    doc_at_store.save!
    another_sync_rep = @another_store.sync!(doc_at_store.versions.all.reverse)
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
    adoc = Document.create!(:uuid => doc.uuid, :world => 'hello')
    sync_rep = @store.sync!(doc.versions.all.reverse)
    sync_rep.conflicts.should be_empty
    sync_rep.non_matching_documents.should == [adoc]
    sync_rep.added_documents.should be_empty
    sync_rep.fast_forwarded_documents.should be_empty
  end

  it "should do nothing if everything is up-to-date" do
    doc = Document.create!(@another_store, :hello => 'world')
    doc.test = 'passed'
    doc.save!
    sync_rep = @store.sync!(doc.versions.all.reverse)
    sync_rep.conflicts.should be_empty
    sync_rep.non_matching_documents.should be_empty
    sync_rep.added_documents.should_not be_empty
    sync_rep.fast_forwarded_documents.should be_empty
    doc_at_store = @store.find(doc.uuid)
    another_sync_rep = @another_store.sync!(doc_at_store.versions.all.reverse)
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
    @store.sync!(doc.versions.all.reverse)
    doc_at_store = @store.find(doc.uuid)
    doc_at_store.ok = true
    doc_at_store.save!
    doc.ok = false
    doc.save!
    another_sync_rep = @another_store.sync!(doc_at_store.versions.all.reverse)
    another_sync_rep.non_matching_documents.should be_empty
    another_sync_rep.added_documents.should be_empty
    another_sync_rep.fast_forwarded_documents.should be_empty
    another_sync_rep.conflicts.should_not be_empty
    conflict = another_sync_rep.conflicts.first
    conflict.rev1[0].should == doc_at_store.version
    conflict.rev2[0].should == doc.version
  end

  it "should try to resolve SynchronizationConflict if it was created" do
    doc = Document.create!(@another_store, :hello => 'world')
    doc.test = 'passed'
    doc.save!
    @store.sync!(doc.versions.all.reverse)
    doc_at_store = @store.find(doc.uuid)
    doc_at_store.ok = true
    doc_at_store.save!
    doc.ok = false
    doc.save!
    resolve_called = 0
    SynchronizationConflict.module_eval do
      define_method('resolve!') do
        resolve_called += 1
      end
    end
    another_sync_rep = @another_store.sync!(doc_at_store.versions.all.reverse)
    resolve_called.should == 1
  end

  it "should add resolution meta to SynchronizationConflict document if it is specified in synchronized document" do
    Object.send!(:remove_const,'SomeStrategy') if defined?(SomeStrategy)
    SomeStrategy = Meta.new

    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new(:resolution_strategy => SomeStrategy)

    # ensure that all metas exist in both stores
    SomeStrategy.document
    SomeMeta.document
    @another_store.sync!(SomeStrategy.document.versions.all.reverse+SomeMeta.document.versions.all.reverse,@store.timestamp)

    doc = SomeMeta.create!(@another_store, :hello => 'world')
    doc.test = 'passed'
    doc.save!
    @store.sync!(doc.versions.all.reverse)
    doc_at_store = @store.find(doc.uuid)
    doc_at_store.ok = true
    doc_at_store.save!
    doc.ok = false
    doc.save!

    some_strategy_resolve = 0
    SomeStrategy.module_eval do
      define_method("resolve!") do
        some_strategy_resolve += 1
      end
    end

    another_sync_rep = @another_store.sync!(doc_at_store.versions.all.reverse)
    conflict = another_sync_rep.conflicts.first
    conflict.should be_a_kind_of(SomeStrategy)
    some_strategy_resolve.should == 1
  end

  it "should store original timestamp in synchronization report" do
    original_timestamp = @store.timestamp.counter
    sync_rep = @store.sync!([])
    sync_rep.timestamp.should == original_timestamp
  end

  it "should store store's document in synchronization report" do
    sync_rep = @store.sync!([])
    sync_rep.store_document.should == @store.document
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
