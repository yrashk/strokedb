require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    @meta = Meta.new(:name => "SomeName", :description => "Something")  
    new_doc = SomeName.document
    new_doc.uuid.should == doc.uuid
    new_doc.previous_version.should_not be_nil
    new_doc.previous_version.should == doc.version
    new_doc.description.should == "Something"
  end
  
  it "should search for specified slots with __meta__ reference merged in" do
    a = SomeName.create!(:slot1 => 1, :slot2 => 2)
    b = SomeName.create!(:slot1 => 1, :slot2 => 2)
    c = SomeName.create!(:slot1 => 2, :slot2 => 2)

    SomeName.find(:slot1 => 1, :slot2 =>2).sort_by {|d| d.uuid}.should == [a,b].sort_by {|d| d.uuid}
  end

  it "should find first document for specified slots with __meta__ reference merged in on #find_or_create" do
    a = SomeName.create!(:slot1 => 1, :slot2 => 2)
    b = SomeName.create!(:slot1 => 1, :slot2 => 2)
    c = SomeName.create!(:slot1 => 2, :slot2 => 2)

    search = SomeName.find_or_create(:slot1 => 1, :slot2 =>2)
    (search == a || search == b).should be_true
  end

  it "should create document for specified slots with __meta__ reference merged in on #find_or_create if such document was not found" do
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
    @meta = Meta.new(:name => "SomeName")  
  end

  it_should_behave_like "Meta module"

end

describe "Meta module without name" do
    
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new
  end
  
  it_should_behave_like "Meta module"
  
  it "should have name defined in the document" do
    SomeName.document.name.should == 'SomeName'
  end
  
end

describe "Meta module with on_initialization callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      on_initialization do |obj|
        Kernel.send!(:on_initialization_called,obj.new?)
      end
    end
  end
  
  it "should call callback block on meta instantiation" do
    Kernel.should_receive(:on_initialization_called).with(true)
    s = SomeName.new
  end

end

describe "Meta module with before_save callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      before_save do |obj|
        Kernel.send!(:before_save_called,obj.new?)
      end
    end
  end
  
  it "should call callback block on Document#save! (before actually saving it)" do
    Kernel.should_receive(:before_save_called).with(true)
    s = SomeName.new
    s.save!
  end

end

describe "Meta module with after_save callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      after_save do |obj|
        Kernel.send!(:after_save_called,obj.new?)
      end
    end
  end
  
  it "should call callback block on Document#save! (after actually saving it)" do
    Kernel.should_receive(:after_save_called).with(false)
    s = SomeName.new
    s.save!
  end

end