require File.dirname(__FILE__) + '/spec_helper'

describe "Inserting single pair into", ViewStorage do

  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @insertion = lambda {|key, val| @view_storage.insert([[key, val]]) }
  end

  it "should should store reference to Document" do
    @value = Document.new
    @insertion.call('key',@value)
    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value].to_set
  end

  it "should should store reference to an arbitrary data" do
    @value = "some data"
    @insertion.call('key',@value)
    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value].to_set
  end

end

describe "Inserting multiple pairs into", ViewStorage do

  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @insertion = lambda do |keys, vals| 
      pairs = []
      keys.each_with_index {|key, i| pairs << [key, vals[i]]}
      @view_storage.insert(pairs) 
    end
  end

  it "should should store references to Documents" do
    @value_1 = Document.new
    @value_2 = Document.new
    @insertion.call(['key','another_key'],[@value1, @value2])
    @view_storage.find('another_key', 'key', nil, nil, nil, false, false).to_set.should == [@value1, @value2].to_set
  end

  it "should should store references to an arbitrary data items" do
    @value_1 = "some data"
    @value_2 = "another data"
    @insertion.call(['key','another_key'],[@value1, @value2])
    @view_storage.find('another_key', 'key', nil, nil, nil, false, false).to_set.should == [@value1, @value2].to_set
  end

end

describe ViewStorage, "with some pairs inserted" do
  
  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @view_storage.insert((1..100).to_a.map {|i| [DefaultKeyEncoder.encode(i),i]})
  end
  
  it "should be able to find entry with specific key" do
    @view_storage.find(nil, nil, DefaultKeyEncoder.encode(50), nil, nil, false, false).to_set.should == [50].to_set
  end

  it "should be able to find entries with specific key range" do
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, nil, nil, false, false).to_set.should == (3..77).to_set
  end

  it "should be able to find entries with only start boundary range" do
    @view_storage.find(DefaultKeyEncoder.encode(77), nil, nil, nil, nil, false, false).to_set.should == (77..100).to_set
  end
  
  it "should be able to find entries with only end boundary range" do
    @view_storage.find(nil, DefaultKeyEncoder.encode(77), nil, nil, nil, false, false).to_set.should == (1..77).to_set
  end
  
  it "should be able to limit results if there is more results than allowed" do
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, 50, nil, false, false).to_set.should == (3..52).to_set
  end

  it "should not limit results if there is less results than allowed" do
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, 100, nil, false, false).to_set.should == (3..77).to_set
  end

  it "should not skip some results if offset is 0 or nil" do
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, nil, nil, false, false).to_set.should == (3..77).to_set
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, nil, 0, false, false).to_set.should == (3..77).to_set
  end
  
  it "should skip some results if offset is specified" do
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, nil, 3, false, false).to_set.should == (6..77).to_set
  end

  
  
end