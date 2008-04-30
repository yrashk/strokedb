require File.dirname(__FILE__) + '/spec_helper'

describe "Meta module", :shared => true do

  it "should be able to instantiate new Document which is also SomeName" do
    obj = SomeName.new
    obj.should be_a_kind_of(Document)
    obj.should be_a_kind_of(SomeName)
  end
  
  it "should be able to instantiate new Document and save it" do
    new_doc = mock("new doc")
    new_doc.should_receive(:save!)
    SomeName.should_receive(:new).and_return(new_doc)
    obj = SomeName.create!
  end
  
  it "should have corresponding document" do
    doc = SomeName.document
    doc.should_not be_nil
    doc.should be_a_kind_of(Meta)
  end

  it "should find document instead of creating it" do
    doc = SomeName.document
    10.times {|i| SomeName.document.uuid.should == doc.uuid }
  end

  it "should save new document version if it was updated" do
    doc = SomeName.document    
    version = doc.version.clone
    new_doc = nil
    2.times do |i|
      Object.send!(:remove_const,'SomeName') if defined?(SomeName)
      SomeName = Meta.new(:description => "Something")  
      new_doc = SomeName.document
    end
    new_doc.uuid.should == doc.uuid
    new_doc.previous_version.should_not be_nil
    new_doc.previous_version.should == version
    new_doc.version.should_not == new_doc.previous_version
    new_doc.description.should == "Something"
  end

  it "should search for specified UUID with meta reference merged in" do
    a = SomeName.create!
    SomeName.find(a.uuid).should == a
  end
  
  it "should search for specified slots with meta reference merged in" do
    a = SomeName.create!(:slot1 => 1, :slot2 => 2)
    b = SomeName.create!(:slot1 => 1, :slot2 => 2)
    c = SomeName.create!(:slot1 => 2, :slot2 => 2)

    SomeName.find(:slot1 => 1, :slot2 =>2).sort_by {|d| d.uuid}.should == [a,b].sort_by {|d| d.uuid}
  end
  
  it "aliases Meta#all to Meta#find" do
    a = SomeName.create!(:slot1 => 3)
    SomeName.all(:slot1 => 3).should == SomeName.find(:slot1 => 3)
  end

  it "should return first found document matching given criteria on call to #first" do
    a = SomeName.create!(:slot1 => 1)
    b = SomeName.create!(:slot1 => 2)
    SomeName.first(:slot1 => 1).should == a
  end
  
  it "should return first document if no args are passed to #first" do
    a = SomeName.create!(:slot1 => 1)
    b = SomeName.create!(:slot1 => 2)
    SomeName.first.should == SomeName.find.first
  end

  it "correctly handles finding via UUID on call to #first" do
    a = SomeName.create!(:slot1 => 5)
    SomeName.first(a.uuid).should == a
  end
  
  it "should return last found document matching given criteria on call to #last" do
    a = SomeName.create!(:slot1 => 1)
    b = SomeName.create!(:slot1 => 1)
    SomeName.last(:slot1 => 1).should == SomeName.find(:slot1 => 1).last
  end
  
  it "should return last document if no args are passed to #last" do
    a = SomeName.create!(:slot1 => 1)
    b = SomeName.create!(:slot1 => 2)
    SomeName.last.should == SomeName.find.last
  end

  it "correctly handles finding via UUID on call to #last" do
    a = SomeName.create!(:slot1 => 5)
    SomeName.last(a.uuid).should == a
  end

  it "should raise ArgumentError unless args size is 1 or 2" do
    a = SomeName.create!(:slot1 => 1, :slot2 => 2)
    lambda { SomeName.find("foo","bar","foobar") }.should raise_error(ArgumentError)
  end
  
  it "should find first document for specified slots with meta reference merged in on #find_or_create" do
    a = SomeName.create!(:slot1 => 1, :slot2 => 2)
    b = SomeName.create!(:slot1 => 1, :slot2 => 2)
    c = SomeName.create!(:slot1 => 2, :slot2 => 2)

    search = SomeName.find_or_create(:slot1 => 1, :slot2 =>2)
    (search == a || search == b).should be_true
  end

  it "should create document for specified slots with meta reference merged in on #find_or_create if such document was not found" do
    a = SomeName.create!(:slot1 => 1, :slot2 => 2)
    b = SomeName.create!(:slot1 => 1, :slot2 => 2)
    c = SomeName.create!(:slot1 => 2, :slot2 => 2)
    
    search = SomeName.find_or_create(:slot1 => 3, :slot2 =>2)
    search.slot1.should == 3
    search.should_not be_new
  end
  
end

describe "Meta module with name" do
  
  before(:each) do
    setup_default_store
    setup_index

    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new
  end
  
  it "should have document's UUID v5 based on nsurl and name" do
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new(:nsurl => "http://some/")
    SomeName.document.uuid.should == Util.sha1_uuid('meta:http://some/#SomeName')
  end

  it "should have specified UUID if it was specified" do
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    uuid = Util.random_uuid
    SomeName = Meta.new(:nsurl => "http://some/", :uuid => uuid)
    SomeName.document.uuid.should == uuid
  end

  it_should_behave_like "Meta module"

end

describe "Meta module without name" do
    
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @some_meta = Meta.new(:nsurl => "http://some/")
  end
  
  it "should not have document's UUID v5 based on nsurl and name" do
    @some_meta.document.uuid.should_not == Util.sha1_uuid('http://some/#SomeName')
  end
end


describe "Meta module without constant definition" do
  
  before(:each) do
    setup_default_store
    setup_index
    @some_name = Meta.new(:name => 'SomeName') do
      def some
      end
    end
  end
  
  it "should not set respective constant" do
    defined?(SomeName).should be_nil
  end
  
  it "should have its name constantizeable anyway" do
    Meta.resolve_uuid_name("","SomeName").constantize.should == @some_name
  end

  it "should be loaded into document on its load" do
    doc = @some_name.create!.reload
    doc.should respond_to(:some)
  end

end

describe "Meta module within no module" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
  end
  
  it "should use Module.nsurl by default" do
    Module.nsurl "test"
    SomeName = Meta.new
    SomeName.document.nsurl.should == Module.nsurl
    Module.nsurl ''
  end
  
  it "should not use Module.nsurl if nsurl is specified" do
    Module.nsurl "test"
    SomeName = Meta.new(:nsurl => 'passed')
    SomeName.document.nsurl.should == 'passed'
    Module.nsurl ''
  end
  
end


describe "Meta module within module" do
  
  before(:each) do
    setup_default_store
    setup_index
    module A
      nsurl "some url"
    end
    A.send!(:remove_const,'SomeName') if defined?(A::SomeName)
  end
  
  it "should use Module.nsurl by default" do
    module A
      SomeName = Meta.new
    end
    A::SomeName.document.nsurl.should == A.nsurl
  end
  
  it "should not use Module.nsurl if nsurl is specified" do
    module A
      SomeName = Meta.new(:nsurl => "nsurl")
    end
    A::SomeName.document.nsurl.should == "nsurl"
  end
  
end

describe "Combined meta module" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'User') if defined?(User)
    Object.send!(:remove_const,'Buyer') if defined?(Buyer)
    Object.send!(:remove_const,'Seller') if defined?(Seller)
    
    User = Meta.new(:x => 1)
    Buyer = Meta.new(:x => 2)
    Seller = Meta.new(:y => 3)
  end

  it "should initialize Document with all metas" do
    d = (User+Buyer+Seller).new
    d[:meta].should == [User.document,Buyer.document,Seller.document]
  end

  it "should be able to find respective documents" do
    d0 = User.create!
    User.find.should == [d0]
    d1 = (User+Buyer).create!
    (User+Buyer).find.should == [d1]
    d2 = (User+Buyer+Seller).create!
    (User+Buyer+Seller).find.should == [d2]
  end
  
  it "should merge #document" do
    (User+Buyer+Seller).document.x.should == 2
    (User+Buyer+Seller).document.y.should == 3
  end
  
  it "should make merged #document immutable" do
    (User+Buyer+Seller).document.should be_a_kind_of(ImmutableDocument)
  end
  
  it "should raise error if trying to Meta + Document" do
    user = User.create!
    lambda { baddoc = (Buyer+user).create! }.should raise_error(RuntimeError)
  end
    
end
