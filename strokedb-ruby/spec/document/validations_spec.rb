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
