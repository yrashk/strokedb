require File.dirname(__FILE__) + '/spec_helper'

describe "New", ViewStorage do
  
  before(:each) do
    @view_storage = ViewStorage.new
  end
  
  it "should be empty" do
    @view_storage.should be_empty
  end
end

describe "Inserting single pair into", ViewStorage do

  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @insertion = lambda {|key, val| @view_storage.insert([[key, val]]) }
  end

  it "should store reference to a Document" do
    pending "move this spec to view_spec"
    @value = Document.new
    @insertion.call('key',@value)
    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value].to_set
  end

  it "should store reference to an arbitrary data" do
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

  it "should store references to Documents" do
    pending "move this spec to view_spec"
    @value_1 = Document.new
    @value_2 = Document.new
    @insertion.call(['key','another_key'],[@value_1, @value_2])
    @view_storage.find('another_key', 'key', nil, nil, nil, false, false).to_set.should == [@value_1, @value_2].to_set
  end

  it "should store references to an arbitrary data items" do
    @value_1 = "some data"
    @value_2 = "another data"
    @insertion.call(['key','another_key'],[@value_1, @value_2])
    @view_storage.find('another_key', 'key', nil, nil, nil, false, false).to_set.should == [@value_1, @value_2].to_set
  end

end


describe "Replacing single pair in", ViewStorage do

  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @insertion = lambda {|key, val| @view_storage.insert([[key, val]]) }
    @replacement = lambda {|oldkey, oldval, key, val| @view_storage.replace([[oldkey, oldval]],[[key, val]]) }
  end

  it "should replace existing reference to Document if such pair exists already" do
    pending "move this spec to view_spec"
    @value_1 = Document.new
    @value_2 = Document.new
    
    @insertion.call('key',@value_1)
    @replacement.call('key',@value_1, 'key',@value_2)
    
    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value_2].to_set
  end

  it "should replace existing reference to an arbitrary data item if such pair exists already" do
    @value_1 = "some data"
    @value_2 = "another data"
    
    @insertion.call('key',@value_1)
    @replacement.call('key',@value_1, 'key',@value_2)
    
    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value_2].to_set
  end

end

describe "Replacing multiple pairs in", ViewStorage do

  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @insertion = lambda do |keys, vals| 
      pairs = []
      keys.each_with_index {|key, i| pairs << [key, vals[i]]}
      @view_storage.insert(pairs) 
    end
    @replacement = lambda do |oldkeys, oldvals, keys, vals| 
      old_pairs = [] 
      new_pairs = []
      oldkeys.each_with_index {|key, i| old_pairs << [key, oldvals[i]]}
      keys.each_with_index {|key, i| new_pairs << [key, vals[i]]}

      @view_storage.replace(old_pairs, new_pairs) 
    end
  end

  it "should replace existing references to Document if such pairs exist already" do
    pending "move this spec to view_spec"
    @value_1 = Document.new
    @value_2 = Document.new
    
    @insertion.call(['key','another_key'],[@value_1, @value_2])
    @replacement.call(['key','another_key'],[@value_1, @value_2],['key','another_key'],[@value_2, @value_1])

    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value_2].to_set
    @view_storage.find(nil, nil, 'another_key', nil, nil, false, false).to_set.should == [@value_1].to_set
  end

  it "should replace existing references to an arbitrary data item if such pairs exist already" do
    @value_1 = "some data"
    @value_2 = "another data"
    
    @value_1 = "some data"
    @value_2 = "another data"
    @insertion.call(['key','another_key'],[@value_1, @value_2])
    @replacement.call(['key','another_key'],[@value_1, @value_2], ['key','another_key'],[@value_2, @value_1])

    @view_storage.find(nil, nil, 'key', nil, nil, false, false).to_set.should == [@value_2].to_set
    @view_storage.find(nil, nil, 'another_key', nil, nil, false, false).to_set.should == [@value_1].to_set
  end

end

describe ViewStorage, "with some pairs inserted" do
  
  before(:each) do
    setup_default_store
    @view_storage = ViewStorage.new
    @view_storage.insert((1..100).to_a.map {|i| [DefaultKeyEncoder.encode(i),i]})
  end
  
  it "should not be empty" do
    @view_storage.should_not be_empty
  end
  
  it "should be empty after clearance" do
    @view_storage.clear!
    @view_storage.should be_empty
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
  
  it "should return both keys and values if told so" do
    @view_storage.find(DefaultKeyEncoder.encode(3), DefaultKeyEncoder.encode(77), nil, nil, nil, false, true).to_set.should == (3..77).to_a.map {|i| [DefaultKeyEncoder.encode(i),i]}.to_set
  end

end