require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def setup
  setup_default_store
  setup_index
  Object.send!(:remove_const,'Song') if defined?(Song)
end

def validate_on_create(should = true)
  create = lambda { Song.create! }
  
  if should
    create.should raise_error(Validations::ValidationError)

    begin
      s = Song.new
      s.save!
    rescue Validations::ValidationError
      exception = $!
      $!.document.should == s
      $!.meta.should == "Song"
      $!.slotname.should == "name"
    end
  else
    create.should_not raise_error(Validations::ValidationError)
  end
end

def validate_on_update(should = true)
  s = Song.create! :name => "My song"
  s.remove_slot!(:name)
  save = lambda { s.save! }
  error = raise_error(Validations::ValidationError)

  should ? save.should(error) : save.should_not(error)
end

describe "validates_presence_of :on => save", :shared => true do
  it "should validate presence of name on document creation" do
    validate_on_create
  end
  
  it "should validate presence of name on document update" do
    validate_on_update
  end
end

describe "Song.validates_presence_of :name" do
  before :each do
    setup
    Song = Meta.new { validates_presence_of :name }
  end
 
  it_should_behave_like "validates_presence_of :on => save"
end

describe "Song.validates_presence_of :name, :on => :save" do
  before :each do
    setup
    Song = Meta.new { validates_presence_of :name, :on => :save }
  end
  
  it_should_behave_like "validates_presence_of :on => save"
end

describe "Song.validates_presence_of :name, :on => :create" do
  before :each do
    setup
    Song = Meta.new { validates_presence_of :name, :on => :create }
  end
  
  it "should validate presence of name on document creation" do
    validate_on_create
  end
  
  it "should not validate presence of name on document update" do
    validate_on_update(false)
  end
end

describe "Song.validates_presence_of :name, :on => :update" do
  before :each do 
    setup
    Song = Meta.new { validates_presence_of :name, :on => :update }
  end
  
  it "should not validate presence of name on document creation" do
    validate_on_create(false)
  end
  
  it "should validate presence of name on document update" do
    validate_on_update(true)
  end
end

describe "User.validates_type_of :email, :as => :email" do
  
  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const, 'User') if defined?(User)
    Object.send!(:remove_const, 'Email') if defined?(Email)
    Email = Meta.new
    User = Meta.new do
      validates_type_of :email, :as => :email
    end
  end
  
  it "should not validate type of :email if none present" do
    lambda { User.create! }.should_not raise_error(Validations::ValidationError)
  end
  
  it "should not raise error if :email is of type Email" do
    e = Email.create!
    lambda { u = User.create!(:email => e) }.should_not raise_error(Validations::ValidationError)
  end
  
  it "should raise error if :email is not an Email" do
    lambda { u = User.create!(:email => "name@server.com") }.should raise_error(Validations::ValidationError)
  end
  
end

describe "User.validates_type_of :email, :as => :string" do
  
  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const, 'User') if defined?(User)
    Object.send!(:remove_const, 'Email') if defined?(Email)
    User = Meta.new do
      validates_type_of :email, :as => :string
    end
  end
    
  it "should not raise error if :email is a String" do
    lambda { u = User.create!(:email => "name@server.com") }.should_not raise_error(Validations::ValidationError)
  end
    
  it "should raise error if :email is not a String" do
    Email = Meta.new
    e = Email.create!
    lambda { u = User.create!(:email => e)}.should raise_error(Validations::ValidationError)
  end
    
end

describe "Meta with validation enabled" do
  
  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const, 'User') if defined?(User)
    User = Meta.new do
      validates_type_of :email, :as => :string
    end
  end
  
  it "should be able to find instances of all documents" do
    doc = User.create! :email => "yrashk@gmail.com"
    User.find.should == [doc]
  end
  
end