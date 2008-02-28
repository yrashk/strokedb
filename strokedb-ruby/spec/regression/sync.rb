require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Database sync" do
  
  before(:all) do
    @path = File.dirname(__FILE__) + '/../test/storages/regression/database-sync'
    build_config!
    FileUtils.rm_rf @path
  end
  
  it "empty save test" do
    M = Meta.new
    save! # this save may cause problems
    M.document
    save!
    
    uuid = M.document.uuid
    
    # reload session
    Object.send :remove_const, 'M'
    build_config!
    
    doc = StrokeDB.default_store.find(uuid)
    doc.should_not be_nil
    doc.uuid.should == uuid
  end
  
  def build_config!
    StrokeDB::Config.build :default => true, :base_path => @path
  end
  
  def save!
    StrokeDB.default_store.chunk_storage.sync_chained_storages!
  end
  
end