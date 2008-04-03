require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def setup
  setup_default_store
  setup_index
  Object.send!(:remove_const, 'Song') if defined?(Song)
  Object.send!(:remove_const, 'User') if defined?(User)
  Object.send!(:remove_const, 'Email') if defined?(Email)
end

describe "Document validation" do
  before :each do
    setup
  end

  it "should treat an empty document as valid" do
    Song = Meta.new
    s = Song.new

    s.should be_valid
    s.save.should be_true
    s.errors.should be_empty
  end

  it "should not treat a document with errors as valid" do
    s = erroneous_stuff

    s.should_not be_valid
    s.save.should be_false
    s.errors.count.should == 2
    %w(123 456).each do |msg|
      s.errors.messages.include?(msg).should be_true
    end
  end

  it "should raise InvalidDocument on a save! call" do
    lambda { erroneous_stuff.save! }.should raise_error(InvalidDocument)
  end

  def erroneous_stuff
    Meta.new do
      on_validation do |doc|
        doc.errors.add(:something, "123")
        doc.errors.add(:other,     "456")
      end
    end.new
  end
end

describe "validates_presence_of" do
  before :each do
    setup 
  end

  it "should tell valid if slot is there" do
    Song = Meta.new { validates_presence_of :name, :on => :save }
    s = Song.new({:name => "Rick Roll"})
    s.should be_valid
  end

  it "should tell invalid if slot is absent" do
    Song = Meta.new { validates_presence_of :name, :on => :save }
    s = Song.new

    s.should_not be_valid
    s.errors.messages.should == [ "Song's name should be present on save" ]
  end
end

# we use validates_presence_of to test common validations behavior (:on, :message)

describe "Validation helpers" do
  before(:each) { setup }

  it "should respect :on => :create" do
    Song = Meta.new { validates_presence_of :name, :on => :create }
    s1 = Song.new
    s1.save.should == false

    s2 = Song.new(:name => "Rick Roll")
    s2.save.should == true
    s2.remove_slot!(:name)
    s2.save.should == true
  end

  it "should respect :on => :update" do
    Song = Meta.new { validates_presence_of :name, :on => :update }
    
    s = Song.new
    s.save.should == true
    s.save.should == false
    s[:name] = "Rick Roll"
    s.save.should == true
  end

  it "should respect :on => :save" do
    Song = Meta.new { validates_presence_of :name, :on => :save }
    s1 = Song.new
    s1.save.should == false

    s2 = Song.new(:name => "Rick Roll")
    s2.save.should == true
    s2.remove_slot!(:name)
    s2.save.should == false
  end

  it "should respect :message" do
    Song = Meta.new do 
      validates_presence_of :name, :on => :save, :message => 'On #{on} Meta #{meta} SlotName #{slotname}'
    end

    s = Song.new
    s.valid?.should be_false
    s.errors.messages.should == [ "On save Meta Song SlotName name" ]
  end
end

describe "validates_type_of" do
  before(:each) do
    setup

    Email = Meta.new
    User = Meta.new { validates_type_of :email, :as => :email }
  end

  it "should treat absent slot as valid" do
    User.new.should be_valid
  end

  it "should actually check the type" do
    e = Email.create!
    User.new(:email => e).should be_valid
  end

  it "should treat other types as invalid" do
    OmgEmail = Meta.new
    e = OmgEmail.create!

    User.new(:email => e).should_not be_valid
    User.new(:email => "name@server.com").should_not be_valid
    User.new(:email => nil).should_not be_valid
  end
end

describe "validates_uniqueness" do
  before :each do
    setup
    User = Meta.new { validates_uniqueness_of :email }
  end

  it "should treat absent slot as valid" do
    u1 = User.create!
    User.new.should be_valid
  end

  it "should treat unique slot values as valid" do
    u1 = User.create!(:email => "name@server.com")
    u2 = User.new(:email => "othername@otherserver.com")
    u2.should be_valid
  end
  
  it "should treat duplicate slot values as invalid" do
    u1 = User.create!(:email => "name@server.com")
    u2 = User.new(:email => "name@server.com")
    u2.should_not be_valid
  end
end

describe "Meta with validation enabled" do
  before(:each) do
    setup
    User = Meta.new { validates_uniqueness_of :email }
  end
  
  it "should be able to find instances of all documents" do
    doc = User.create! :email => "yrashk@gmail.com"
    User.find.should == [doc]
  end
end
