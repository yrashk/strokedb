require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Database search" do
  
  before(:all) do
    @path = File.dirname(__FILE__) + "/../../test/storages/database_search"
    FileUtils.rm_rf @path
    @f_storage = FileChunkStorage.new(@path + "/storage")
    @f_storage.clear!
    @index_storage = InvertedListFileStorage.new(@path+"/index")
    @index_storage.clear!
    @index  = InvertedListIndex.new(@index_storage)
    @index2 = InvertedListIndex.new(@index_storage)
    
    @f_store = SkiplistStore.new(:storage => @f_storage, :cut_level => 4, :index => @index)
    @index.document_store = @f_store
    @index2.document_store = @f_store
    
    @profile_meta = Document.create!(@f_store, :name => 'Profile', 
                                               :non_indexable_slots => [ :bio, :__version__, :__previous_version__ ])
  end
  
  # Leave for investigation
  # after(:all) do
  #   FileUtils.rm_rf @path
  # end
  
  it "should add new doc" do
    doc = Document.create!(@f_store, :name => "Oleg", :state => 'Russia', :age => 21, :__meta__ => @profile_meta)
    doc.uuid.should_not be_nil
    @oleg_uuid = doc.uuid
    results = @index.find(:name => "Oleg")
    results.should_not be_empty
    results[0].uuid.should == @oleg_uuid
  end
  
  it "should find doc in a separate index instance" do
    results = @index2.find(:name => "Oleg", :__meta__ => @profile_meta)
    results.should_not be_empty
    results[0]["name"].should == "Oleg"
  end
  
  it "should store & find several docs" do
    doc = Document.create!(@f_store, :name => "Yurii", :state => 'Ukraine', :__meta__ => @profile_meta)
    doc.save!
    @yura_uuid = doc.uuid
    results = @index.find(:name => "Yurii")
    results.should_not be_empty
    results[0].uuid.should == @yura_uuid
  end

  it "should find all profiles" do
    results = @index.find(:__meta__ => @profile_meta)
    results.should_not be_empty
    results.map(&:uuid).to_set == [ @yura_uuid, @oleg_uuid ].to_set 
  end
  
  it "should find all profiles from Ukraine" do
    results = @index.find(:__meta__ => @profile_meta, :state => 'Ukraine')
    results.should_not be_empty
    results.map(&:uuid).to_set == [ @yura_uuid ].to_set 
  end
  
  it "should remove info from index" do
    results = @index.find(:name => 'Oleg')
    oleg = results[0]
    oleg[:name] = 'Oleganza'
    oleg.save!
    results = @index.find(:name => 'Oleg')
    results.should be_empty
    results = @index.find(:name => 'Oleganza')
    results[0].uuid.should == oleg.uuid
  end
  
end

