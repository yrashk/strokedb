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