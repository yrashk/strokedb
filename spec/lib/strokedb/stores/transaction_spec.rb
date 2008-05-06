require File.dirname(__FILE__) + '/spec_helper'

describe 'Transaction', :shared => true do

  it "should have UUID" do
    @txn.uuid.should match(/#{UUID_RE}/)
  end
  
  it "should act as a store for documents initialized within transaction scope" do
    @txn.execute do
      @doc = Document.new
      @doc.store.should == @txn
    end
  end
  
  it "should revert newly instantiated documents' store to main one outside of transaction scope" do
    @txn.execute do
      @doc = Document.new
    end
    @doc.store.should == @txn.store
  end
  
  it "should acts as a store for already initialized documents" do
    @doc = Document.new
    @txn.execute do
      @doc.store.should == @txn
    end
  end
  
  it "should return block result on block execution" do
    @txn.execute do
      :some_result
    end.should == :some_result
  end

  it "should be able to find already existing document within transaction scope" do
    @doc = Document.create!
    @txn.execute do
      Document.find(@doc.uuid).should == @doc
    end
  end
  
  it "should be able to save new documents within block execution without exposing them to original storage" do
    @txn.execute do
      @doc = Document.create!
      Document.find(@doc.uuid).should == @doc
    end
    Document.find(@doc.uuid).should be_nil
  end
  
  it "should see its own head version of the document" do
    @doc = Document.create!
    @txn.execute do |txn|
      @doc.update_slots! :new_version => 'yes'
      @doc.store.head_version(@doc.uuid).should == @doc.version
    end
    @doc.store.head_version(@doc.uuid).should == @doc.versions.previous.version
  end

  it "should be able to commit transaction" do
    @txn.execute do |txn|
      @doc = Document.create!
      txn.commit!
    end
    Document.find(@doc.uuid).should == @doc
  end

  it "should be able to rollback transaction" do
    @txn.execute do |txn|
      @doc = Document.create!
      txn.rollback!
      Document.find(@doc.uuid).should be_nil
    end
    Document.find(@doc.uuid).should be_nil
  end
  
  it "should pop transaction on code that raises some exception" do
    lambda do
      @txn.execute do |txn|
        raise Exception
      end
    end.should raise_error(Exception)
    Thread.current[:strokedb_transactions].should be_empty
  end

  it "should pop transaction on code that raises no exception" do
    lambda do
      @txn.execute do |txn|
      end
    end.should_not raise_error(Exception)
    Thread.current[:strokedb_transactions].should be_empty
  end
  
    
end

describe "New", Transaction do
  
  before(:each) do
    StrokeDB::Config.build :default => true, :storages => [:memory], :base_path => TEMP_STORAGES + '/txn'
    @txn = Transaction.new(:store => StrokeDB.default_store)
    Thread.current[:strokedb_transactions] = nil
  end
  
  it_should_behave_like 'Transaction'
  
end