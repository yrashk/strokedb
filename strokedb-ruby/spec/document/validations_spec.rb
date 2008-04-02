require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Song.validates_presence_of :name" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Song') if defined?(Song)
    Song = Meta.new do
      validates_presence_of :name
    end
  end
  
  it "should validate presence of name on document creation" do
    lambda { Song.create! }.should raise_error(Validations::ValidationError)
    begin
      s = Song.new
      s.save!
    rescue Validations::ValidationError
      exception = $!
      $!.document.should == s
      $!.meta.should == "Song"
      $!.slotname.should == "name"
    end
  end
  
  it "should validate presence of name on document update" do
    s = Song.create! :name => "My song"
    s.remove_slot!(:name)
    lambda do
      s.save!
    end.should raise_error(Validations::ValidationError)
  end

end

describe "Song.validates_presence_of :name, :on => :save" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Song') if defined?(Song)
    Song = Meta.new do
      validates_presence_of :name, :on => :save
    end
  end
  
  it "should validate presence of name on document creation" do
    lambda { Song.create! }.should raise_error(Validations::ValidationError)
    begin
      s = Song.new
      s.save!
    rescue Validations::ValidationError
      exception = $!
      $!.document.should == s
      $!.meta.should == "Song"
      $!.slotname.should == "name"
    end
  end
  
  it "should validate presence of name on document update" do
    s = Song.create! :name => "My song"
    s.remove_slot!(:name)
    lambda do
      s.save!
    end.should raise_error(Validations::ValidationError)
  end

end


describe "Song.validates_presence_of :name, :on => :create" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Song') if defined?(Song)
    Song = Meta.new do
      validates_presence_of :name, :on => :create
    end
  end
  
  it "should validate presence of name on document creation" do
    lambda { Song.create! }.should raise_error(Validations::ValidationError)
    begin
      s = Song.new
      s.save!
    rescue Validations::ValidationError
      exception = $!
      $!.document.should == s
      $!.meta.should == "Song"
      $!.slotname.should == "name"
    end
  end
  
  it "should not validate presence of name on document update" do
    s = Song.create! :name => "My song"
    s.remove_slot!(:name)
    lambda do
      s.save!
    end.should_not raise_error(Validations::ValidationError)
  end

end




describe "Song.validates_presence_of :name, :on => :update" do

  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'Song') if defined?(Song)
    Song = Meta.new do
      validates_presence_of :name, :on => :update
    end
  end
  
  it "should not validate presence of name on document creation" do
    lambda { Song.create! }.should_not raise_error(Validations::ValidationError)
  end
  
  it "should validate presence of name on document update" do
    s = Song.create! :name => "My song"
    s.remove_slot!(:name)
    lambda do
      s.save!
    end.should raise_error(Validations::ValidationError)
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