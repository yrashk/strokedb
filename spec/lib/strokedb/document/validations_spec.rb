require File.dirname(__FILE__) + '/spec_helper'

def validations_setup
  setup_default_store
  setup_index
  Object.send!(:remove_const, 'Foo') if defined?(Foo)
  Object.send!(:remove_const, 'Bar') if defined?(Bar)
  Object.send!(:remove_const, 'User') if defined?(User)
  Object.send!(:remove_const, 'Email') if defined?(Email)
  Object.send!(:remove_const, 'Item') if defined?(Item)
  Object.send!(:remove_const, 'OneMoreItem') if defined?(OneMoreItem)
end

def erroneous_stuff
  Meta.new(:name => "ErroneousStuff") do
    on_validation do |doc|
      doc.errors.add(:something, "123")
      doc.errors.add(:other,     "456")
    end
  end.new
end

describe "Document validation" do
  before :each do
    validations_setup
  end

  it "should treat an empty document as valid" do
    Foo = Meta.new
    s = Foo.new

    s.should be_valid
    s.errors.should be_empty
  end

  it "should not treat a document with errors as valid" do
    s = erroneous_stuff

    s.should_not be_valid
    s.errors.messages.sort.should == %w(123 456)
  end

  it "should raise InvalidDocumentError on a save! call" do
    lambda { erroneous_stuff.save! }.should raise_error(InvalidDocumentError)
  end

  it "should not raise InvalidDocumentError on a save!(false) call" do
    lambda { erroneous_stuff.save!(false) }.should_not raise_error(InvalidDocumentError)
  end
end

describe "Document with errors" do
  before :each do
    validations_setup
    @erroneous_doc = erroneous_stuff
  end

  it "should return the number of errors" do
    @erroneous_doc.should_not be_valid
    @erroneous_doc.errors.size.should == 2
  end
  
  it "should yield each attribute and associated message per error added" do
    @erroneous_doc.should_not be_valid
    @erroneous_doc.errors.each { }.should == {"something"=>["123"], "other"=>["456"]}
  end
  
end

describe "validates_presence_of" do
  before :each do
    validations_setup 
  end

  it "should tell valid if slot is there" do
    Foo = Meta.new { validates_presence_of :name, :on => :save }
    s = Foo.new({:name => "Rick Roll"})
    s.should be_valid
  end

  it "should tell invalid if slot is absent" do
    Foo = Meta.new { validates_presence_of :name, :on => :save }
    s = Foo.new

    s.should_not be_valid
    s.errors.messages.should == [ "Foo's name should be present on save" ]
  end
end

describe "Validation helpers" do
  before(:each) { validations_setup }

  it "should respect :on => :create" do
    Foo = Meta.new { validates_presence_of :name, :on => :create }
    s1 = Foo.new
    bang { s1.save! }

    s2 = Foo.new(:name => "Rick Roll")
    no_bang { s2.save! }
    s2.remove_slot!(:name)
    no_bang { s2.save! }
  end

  it "should respect :on => :update" do
    Foo = Meta.new { validates_presence_of :name, :on => :update }
    
    s = Foo.new
    no_bang { s.save! }
    bang { s.save! }
    s[:name] = "Rick Roll"
    no_bang { s.save! }
  end

  it "should respect :on => :save" do
    Foo = Meta.new { validates_presence_of :name, :on => :save }
    s1 = Foo.new
    bang { s1.save! }

    s2 = Foo.new(:name => "Rick Roll")
    no_bang { s2.save! }
    s2.remove_slot!(:name)
    bang { s2.save! }
  end

  it "should respect :message" do
    Foo = Meta.new do 
      validates_presence_of :name, :on => :save, :message => 'On #{on} Meta #{meta} SlotName #{slotname}'
    end

    s = Foo.new
    s.valid?.should be_false
    s.errors.messages.should == [ "On save Meta Foo SlotName name" ]
  end

  it "should allow to use document slot for :if and :unless evaluation" do
    Foo = Meta.new do validates_presence_of :name, :on => :save, :if => :slot end
    bang { Foo.create!(:slot => true) }
    no_bang { Foo.create!(:slot => false) }
    
    Bar = Meta.new do validates_presence_of :name, :on => :save, :unless => :slot end
    no_bang { Bar.create!(:slot => true) }
    bang { Bar.create!(:slot => false) }
  end
  
  it "should raise an ArgumentError when given something not callable for :if and :unless" do
    lambda do
      Meta.new { validates_presence_of :name, :on => :save, :if => 123  }
    end.should raise_error(ArgumentError)

    lambda do
      Meta.new { validates_presence_of :name, :on => :save, :if => lambda { }  }
    end.should raise_error(ArgumentError)

    lambda do
      Meta.new { validates_presence_of :name, :on => :save, :unless => 123  }
    end.should raise_error(ArgumentError)

    lambda do
      Meta.new { validates_presence_of :name, :on => :save, :unless => lambda { }  }
    end.should raise_error(ArgumentError)

  end

  def bang
    lambda { yield }.should raise_error(InvalidDocumentError)
  end

  def no_bang
    lambda { yield }.should_not raise_error(InvalidDocumentError)
  end
end

describe "validates_type_of" do
  before :each do
    validations_setup

    Email = Meta.new
    User = Meta.new { validates_type_of :email, :as => :email }
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
    u = User.new(:email => nil)
    u.should_not be_valid
    u.errors.messages.should == [ "User's email should be of type Email" ]
  end
  
  it "should treat absent slot as valid with :allow_nil => true" do
    Foo = Meta.new { validates_type_of :email, :as => :email, :allow_nil => true }
    Foo.new.should be_valid
  end

end

describe "validates_format_of" do
  before(:each) do
    validations_setup
    User = Meta.new { validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  end

  it "should be valid when :email value match regexp" do
    User.new(:email => 'cool@strokedb.com').should be_valid
  end
  
  it "should be invalid when :email value does not match regexp" do
    User.new(:email => 'cool-strokedb.com').should_not be_valid
  end
  
  it "should raise an exception if no regex is provided" do
    lambda { Meta.new { validates_format_of :email, :with => "nothing" } }.should raise_error(ArgumentError)
  end
end

describe "validates_uniqueness_of" do
  before :each do
    validations_setup
    User = Meta.new { validates_uniqueness_of :email }
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
    u2.errors.messages.should == [ "A document with a email of name@server.com already exists" ]
  end

  it "should respect slot name" do
    u1 = User.create!(:email => "name@server.com")
    u2 = User.new(:otherfield => "name@server.com")
    u2.should be_valid
  end
  
  describe "document with multiple metas" do
    before :each do
      validations_setup
      Object.send!(:remove_const,'User') if defined?(User)
      Object.send!(:remove_const,'Admin') if defined?(Admin)
      
      User = Meta.new { validates_uniqueness_of :email }
      Admin = Meta.new
    end
    
    it "should be valid" do
      u = (User+Admin).create!(:email => 'foo@bar.org')
      u.should be_valid
    end
    
    it "should be valid" do
      u = User.create!(:email => 'foo@bar.org')
      u.should be_valid
      u.metas << Admin
      u.should be_valid
    end

    it "should not be valid" do
      u = User.create!(:email => 'foo@bar.org')
      u.should be_valid
      a = Admin.create!(:email => 'foo@bar.org')
      a.should be_valid

      u.metas << Admin
      a.should be_valid
      u.should_not be_valid
    end
  end
  
  describe "should allow to modify an existing document" do
    it "test 1" do
      u = User.create!(:email => "name@server.com", :status => :newbie)
      u.status = :hacker
      u.should be_valid
      u.save!
      u.status = :hax0r
      u.should be_valid
      u.save!
      u.email = "hax0r@hax0r.com"
      u.should be_valid
      u.save!
      u.email = "name@server.com"
      u.status = :newbie_again
      u.should be_valid
      u.save!
      u.email = "hax0r@hax0r.com"
      u.should be_valid
    end

    it "test 2" do
      Foo = Meta.new do
        validates_uniqueness_of :login
        virtualizes :blah
      end

      foo = Foo.create!(:login => "vasya")

      foo.somefield = 777
      foo.should be_valid
    end
  end

  it "should respect :allow_nil set to false" do
    Foo = Meta.new { validates_uniqueness_of :slot, :allow_nil => false }
    Foo.create!(:slot => nil)
    Foo.new.should_not be_valid
  end
  
  it "should respect :allow_nil set to true" do
    Foo = Meta.new { validates_uniqueness_of :slot, :allow_nil => true }
    Foo.create!(:slot => nil)
    Foo.new.should be_valid
  end
  
  it "should default :allow_nil to false" do
    Foo = Meta.new { validates_uniqueness_of :slot }
    Foo.create!(:slot => nil)
    Foo.new.should_not be_valid
  end
  
  it "should respect :allow_blank set to false" do
    Foo = Meta.new { validates_uniqueness_of :slot, :allow_blank => false }
    Foo.create!(:slot => "")
    Foo.new.should_not be_valid
  end
  
  it "should respect :allow_blank set to true" do
    Foo = Meta.new { validates_uniqueness_of :slot, :allow_blank => true }
    Foo.create!(:slot => "")
    Foo.new.should be_valid
  end
  
  it "should default :allow_blank to false" do
    Foo = Meta.new { validates_uniqueness_of :slot }
    Foo.create!(:slot => "")
    Foo.new.should_not be_valid
  end
  
  it "should respect :case_sensitive"
end

describe "validates_confirmation_of" do
  before :each do
    validations_setup
    User = Meta.new { validates_confirmation_of :password }
  end

  it "should be valid when confirmed" do
    User.new(:password => "sekret", :password_confirmation => "sekret").should be_valid
  end
  
  it "should be valid when confirmation is not set" do
    User.new(:password => "sekret").should be_valid
  end
  
  it "should not be valid when not confirmed" do
    u = User.new(:password => "sekret", :password_confirmation => "invalid_guess")
    u.should_not be_valid
    u.errors.messages.should == [ "User's password doesn't match confirmation" ]
  end

  it "should not serialize confirmation slot" do
    u = User.create!(:password => "sekret", :password_confirmation => "sekret")
    User.find(u.uuid).has_slot?("password_confirmation").should_not be_true
  end
end

describe "validates_acceptance_of" do
  before :each do
    validations_setup
  end

  it "should treat accepted value as valid" do
    Meta.new(:name => 'some') { validates_acceptance_of :eula, :accept => "yep" }.new(:eula => "yep").should be_valid
  end
  
  it "should treat not accepted value as invalid" do
    Meta.new(:name => 'some') { validates_acceptance_of :eula, :accept => "yep" }.new(:eula => "nope").should_not be_valid
  end

  it "should respect allow_nil" do
    Meta.new(:name => 'some') { validates_acceptance_of :eula, :accept => "yep", :allow_nil => true }.new.should be_valid
    Meta.new(:name => 'some') { validates_acceptance_of :eula, :accept => "yep", :allow_nil => false }.new.should_not be_valid
  end

  it "should set :allow_nil to true by default" do
    Meta.new(:name => 'some') { validates_acceptance_of :eula, :accept => "yep" }.new.should be_valid
  end

  it "should set :accept to \"1\" by default" do
    Meta.new(:name => 'some') { validates_acceptance_of :eula }.new(:eula => "1").should be_valid
  end

  it "should make a slot virtual" do
    Foo = Meta.new{ validates_acceptance_of :eula, :accept => "yep" }
    f = Foo.create!(:eula => "yep")
    Foo.find(f.uuid).has_slot?("eula").should_not be_true
  end
end

describe "validates_length_of" do
  before :each do
    validations_setup
  end
 
  describe "options handling" do
    it "should raise ArgumentError when more than one range option is specified" do
      arg_bang { Meta.new(:name => 'some') { validates_length_of :name, :is => 10, :maximum => 20 } }
      arg_bang { Meta.new(:name => 'some') { validates_length_of :name, :is => 10, :within => 1..20 } }
    end

    it "should raise ArgumentError when no range option is specified" do
      arg_bang { Meta.new(:name => 'some') { validates_length_of :name } }
    end

    it "should raise ArgumentError when not Range given to :in or :within" do
      arg_bang { Meta.new(:name => 'some') { validates_length_of :name, :in => 10 } }
      arg_bang { Meta.new(:name => 'some') { validates_length_of :name, :within => "somewhere between one and a million" } }
    end

    it "should raise ArgumentError when something other than nonnegative Integer is given to :is, :minimum, :maximum" do
      %w(is minimum maximum).each do |arg|
        arg_bang { Meta.new(:name => 'some') { validates_length_of :name, arg => "blah" } }
        arg_bang { Meta.new(:name => 'some') { validates_length_of :name, arg => -1 } }
      end
    end
    
    def arg_bang
      lambda { yield }.should raise_error(ArgumentError)
    end
  end
  
  %w(within in).each do |within|
    describe ":#{within}" do
      before :each do
        Foo = Meta.new { validates_length_of :bar, within => 10..50 }
      end

      it "should consider valid when slot is within the range" do
        Foo.new(:bar => "*"*30).should be_valid
        Foo.new(:bar => [1]*30).should be_valid
      end
      
      it "should consider invalid when slot is too small" do
        f = Foo.new(:bar => "12345")
        f.should_not be_valid
        f.errors.messages.should == [ "bar is too short (minimum is 10 characters)" ]
        Foo.new(:bar => [1]*5).should_not be_valid
      end
      
      it "should consider invalid when slot is too big" do
        f = Foo.new(:bar => "!"*100)
        f.should_not be_valid
        f.errors.messages.should == [ "bar is too long (maximum is 50 characters)" ]
        Foo.new(:bar => [1]*100).should_not be_valid
      end

      it "should respect :too_short" do
        Bar = Meta.new { validates_length_of :foo, within => 1..5, :too_short => "blah %d" }
        b = Bar.new(:foo => "")
        b.should_not be_valid
        b.errors.messages.should == [ "blah 1" ]
      end
      
      it "should respect :too_long" do
        Bar = Meta.new { validates_length_of :foo, within => 1..5, :too_long => "blah %d" }
        b = Bar.new(:foo => "123456")
        b.should_not be_valid
        b.errors.messages.should == [ "blah 5" ]
      end
    end
  end

  describe ":is" do
    before :each do
      Foo = Meta.new { validates_length_of :bar, :is => 4 }
    end

    it "should consider valid when slot value has the right length" do
      Foo.new(:bar => "1234").should be_valid
      Foo.new(:bar => %w(ein zwei drei Polizei)).should be_valid
    end
    
    it "should consider invalid when slot value has invalid length" do
      f = Foo.new(:bar => "12345")
      f.should_not be_valid
      f.errors.messages.should == [ "bar has the wrong length (should be 4 characters)" ]
    
      Foo.new(:bar => %w(ein zwei alles)).should_not be_valid
    end

    it "should respect :message" do
      Bar = Meta.new { validates_length_of :foo, :is => 66, :message => "fkup %d" }
      b = Bar.new(:foo => "123456")
      b.should_not be_valid
      b.errors.messages.should == [ "fkup 66" ]
    end
  end

  describe ":minimum" do
    before :each do
      Foo = Meta.new { validates_length_of :bar, :minimum => 4 }
    end

    it "should consider valid when slot value has the right length" do
      Foo.new(:bar => "1234").should be_valid
      Foo.new(:bar => "12345").should be_valid
      Foo.new(:bar => %w(ein zwei drei vier Polizei)).should be_valid
    end
    
    it "should consider invalid when slot value has invalid length" do
      f = Foo.new(:bar => "125")
      f.should_not be_valid
      f.errors.messages.should == [ "bar is too short (minimum is 4 characters)" ]
    
      Foo.new(:bar => %w(ein zwei alles)).should_not be_valid
    end
    
    it "should respect :message" do
      Bar = Meta.new { validates_length_of :foo, :minimum => 66, :message => "fkup %d" }
      b = Bar.new(:foo => "123456")
      b.should_not be_valid
      b.errors.messages.should == [ "fkup 66" ]
    end
  end
  
  describe :maximum do
    before :each do
      Foo = Meta.new { validates_length_of :bar, :maximum => 4 }
    end

    it "should consider valid when slot value has the right length" do
      Foo.new(:bar => "1234").should be_valid
      Foo.new(:bar => "123").should be_valid
      Foo.new(:bar => %w(ein zwei drei)).should be_valid
    end
    
    it "should consider invalid when slot value has invalid length" do
      f = Foo.new(:bar => "123456")
      f.should_not be_valid
      f.errors.messages.should == [ "bar is too long (maximum is 4 characters)" ]
    
      Foo.new(:bar => %w(ein zwei drei vier Polizei)).should_not be_valid
    end
    
    it "should respect :message" do
      Bar = Meta.new { validates_length_of :foo, :maximum => 66, :message => "fkup %d" }
      b = Bar.new(:foo => "6"*67)
      b.should_not be_valid
      b.errors.messages.should == [ "fkup 66" ]
    end
  end

  it "should respect :allow_nil" do
    Meta.new(:name => 'some') { validates_length_of :bar, :is => 10, :allow_nil => false }.new.should_not be_valid
    Meta.new(:name => 'some') { validates_length_of :bar, :is => 10, :allow_nil => true  }.new.should     be_valid
  end

  it "should respect :allow_blank" do
    Foo = Meta.new { validates_length_of :bar, :is => 10, :allow_blank => false }
    Foo.new.should_not be_valid
    Foo.new(:bar => "   ").should_not be_valid
    
    Bar = Meta.new { validates_length_of :bar, :is => 10, :allow_blank => true }
    Bar.new.should be_valid
    Bar.new(:bar => "   ").should be_valid
  end
end

describe "validates_inclusion_of" do
  before :each do
    validations_setup
    Item = Meta.new do
      validates_inclusion_of :gender, :in => %w( m f )
      validates_inclusion_of :age, :in => 0..99
    end
  end
  
  it "should raise ArgumentError unless option :in is suplied" do
    lambda do
      Meta.new { validates_inclusion_of :format }
    end.should raise_error(ArgumentError)
  end
  
  it "should raise ArgumentError unless param is an enumerable" do
    lambda do
      Meta.new { validates_inclusion_of :format, :in => 42 }
    end.should raise_error(ArgumentError)
  end
    
  it "should be valid" do
    i = Item.new(:gender => 'm', :age => 42)
    i.should be_valid
    i.errors.messages.should be_empty
  end
  
  it "should not be valid" do
    i = Item.new(:gender => 'x', :age => 'x')
    i.should_not be_valid
    i.errors.messages.should == [ "Value of gender is not included in the list", "Value of age is not included in the list" ]
  end
  
  it "should be invalid without gender and age set" do
    Item.new.should_not be_valid
  end
end

describe "validates_exclusion_of" do
  before :each do
    validations_setup
    Item = Meta.new do
      validates_exclusion_of :gender, :in => %w( m f )
      validates_exclusion_of :age, :in => 30..70
    end
  end
  
  it "should raise ArgumentError unless option :in is suplied" do
    lambda do
      Meta.new { validates_exclusion_of :gender }
    end.should raise_error(ArgumentError)
  end
  
  it "should raise ArgumentError unless param is an enumerable" do
    lambda do
      Meta.new { validates_inclusion_of :gender, :in => 42 }
    end.should raise_error(ArgumentError)
  end
    
  it "should be valid" do
    i = Item.new(:gender => 'x', :age => 25)
    i.should be_valid
  end
  
  it "should not be valid" do
    i = Item.new(:gender => 'm', :age => 42)
    i.should_not be_valid
    i.errors.messages.should == [ "Value of gender is reserved", "Value of age is reserved" ]
  end
end

describe "validates_associated" do
  before :each do
    validations_setup

    Foo = Meta.new { has_many :bars; validates_associated :bars }
    Bar = Meta.new { has_many :items; validates_associated :items }
    Item = Meta.new { validates_associated :associate }
    OneMoreItem = Meta.new { validates_associated :associate; validates_presence_of :something }
    User = Meta.new
  end

  it "should consider not existing association as valid" do
    Foo.new.should be_valid
  end

  it "should consider valid when associated document is also valid" do
    perfectly_valid = User.new
    Item.new(:associate => perfectly_valid).should be_valid
  end

  it "should consider invalid when associated document is invalid" do
    invalid = erroneous_stuff
    invalid.should_not be_valid
    item = Item.new(:associate => invalid)
    item.should_not be_valid
    item.errors.messages.should == [ "associate is invalid" ]
  end

  it "should work with has_many association" do
    f = Foo.new
    f.bars << Bar.new
    f.should be_valid
    f.bars << Bar.new
    f.should be_valid

    err = erroneous_stuff

    lambda { f.bars << err }.should raise_error(InvalidDocumentError)
    f.should be_valid
  end
  
  it "should work with a document chain" do
    i3 = erroneous_stuff
    i3.should_not be_valid

    i2 = Item.new
    i2.should be_valid
    i2.associate = i3
    i2.should_not be_valid

    i1 = Item.new
    i1.should be_valid
    i1.associate = i2
    i1.should_not be_valid

    i1.associate = i3
    i1.should_not be_valid
    i1.associate = nil
    i1.should be_valid
  end
  
  it "should catch direct circular referenced validations" do
    i = Item.new
    i1 = Item.new(:associate => i)
    i.associate = i1
    lambda { i.valid? }.should_not raise_error(SystemStackError)
    i.should be_valid
    oi = OneMoreItem.new
    oi1 = OneMoreItem.new(:associate => oi)
    oi.associate = oi1
    oi.should_not be_valid
    oi1.should_not be_valid
  end

  it "should catch circular referenced validations through has_many association" do
    b = Bar.new
    b.items << (i = Item.new(:associate => b))
    lambda { b.valid? }.should_not raise_error(SystemStackError)
    lambda { i.valid? }.should_not raise_error(SystemStackError)
  end

end

describe "validates_numericality_of" do
  before :each do
    validations_setup
  end
 
  describe "general behaviour" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :price
      end
    end
    
    it "should raise error on String value" do
      i = Item.new(:price => "A")
      i.should_not be_valid
      i.errors.messages.should == [ "price is not a number" ]
    end
    
    it "should treat integer as valid" do
      i = Item.new(:price => 1)  
      i.should be_valid
    end
    
    it "should treat negative integer as valid" do
      i = Item.new(:price => -1)  
      i.should be_valid
    end
    
    it "should treat float as valid" do
      i = Item.new(:price => 2.5)
      i.should be_valid
    end
    
    it "should treat negative float as valid" do
      i = Item.new(:price => -2.5)
      i.should be_valid
    end
    
    it "should treat float in exponential notation as valid" do
      i = Item.new(:price => "1.23456E-3")
      i.should be_valid
    end
  end

  describe "should respect :only_integer" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :price, :only_integer => true
      end
    end
    
    it "should treat integer as valid when :only_integer is specified" do
      Item.new(:price => 123).should be_valid
    end
    
    it "should treat integer in string as valid when :only_integer is specified" do
      Item.new(:price => "123").should be_valid
    end
    
    it "should treat string as invalid when :only_integer is specified" do
      i = Item.new(:price => "ququ")
      i.should_not be_valid
      i.errors.messages.should == [ "price must be integer" ]
    end

    it "should treat float as invalid when :only_integer is specified" do
      i = Item.new(:price => 1.5)
      i.should_not be_valid
      i.errors.messages.should == [ "price must be integer" ]
    end
  end

  describe "should respect :greater_than" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :number, :greater_than => 42
      end
    end
    
    it "should raise ArgumentError if value is not numeric" do
      lambda do
        Meta.new { validates_numericality_of :number, :greater_than => "chicken" }
      end.should raise_error(ArgumentError)
    end
    
    it "should be valid if value > 42" do
      i = Item.new(:number => 44)
      i.should be_valid
      i.errors.messages.should be_empty
      i.number = 44.3
      i.should be_valid
      i.errors.messages.should be_empty  
    end
    
    it "should not be valid if value < 42" do
      i = Item.new(:number => 41)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be greater than 42" ]
    end
    
    it "should not be valid if value == 42" do
      i = Item.new(:number => 42)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be greater than 42" ]
    end
  end
  
  describe "should respect :greater_than_or_equal_to" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :number, :greater_than_or_equal_to => 42
      end
    end
    
    it "should raise ArgumentError if value is not numeric" do
      lambda do
        Meta.new { validates_numericality_of :number, :greater_than => "chicken" }
      end.should raise_error(ArgumentError)
    end
    
    it "should be valid if value > 42" do
      i = Item.new(:number => 44)
      i.should be_valid
      i.number = 44.3
      i.should be_valid
    end
    
    it "should be valid if value == 42" do
      i = Item.new(:number => 42)
      i.should be_valid
    end
    
    it "should not be valid if value < 42" do
      i = Item.new(:number => 41)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be greater than or equal to 42" ]
    end
  end
  
  describe "should respect :equal_to" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :number, :equal_to => 42
      end
    end
    
    it "should raise ArgumentError if value is not numeric" do
      lambda do
        Meta.new { validates_numericality_of :number, :greater_than => "chicken" }
      end.should raise_error(ArgumentError)
    end
    
    it "should be valid if value == 42" do
      i = Item.new(:number => 42)
      i.should be_valid
      i.errors.messages.should be_empty
    end
    
    it "should not be valid if value > 42" do
      i = Item.new(:number => 44)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be equal to 42" ]
    end
    
    it "should not be valid if value < 42" do
      i = Item.new(:number => 41)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be equal to 42" ]
    end
  end
  
  describe "should respect :less_than" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :number, :less_than => 42
      end
    end
    
    it "should raise ArgumentError if value is not numeric" do
      lambda do
        Meta.new { validates_numericality_of :number, :less_than => "chicken" }
      end.should raise_error(ArgumentError)
    end
    
    it "should be valid if value < 42" do
      i = Item.new(:number => 41)
      i.should be_valid
      i.errors.messages.should be_empty
      i.number = 41.3
      i.should be_valid
      i.errors.messages.should be_empty  
    end
    
    it "should not be valid if value > 42" do
      i = Item.new(:number => 43)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be less than 42" ]
    end
    
    it "should not be valid if value == 42" do
      i = Item.new(:number => 42)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be less than 42" ]
    end
  end
  
  describe "should respect :less_than_or_equal_to" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :number, :less_than_or_equal_to => 42
      end
    end
    
    it "should raise ArgumentError if value is not numeric" do
      lambda do
        Meta.new { validates_numericality_of :number, :less_than_or_equal_to => "chicken" }
      end.should raise_error(ArgumentError)
    end
    
    it "should be valid if value < 42" do
      i = Item.new(:number => 41)
      i.should be_valid
      i.errors.messages.should be_empty
      i.number = 41.3
      i.should be_valid
      i.errors.messages.should be_empty  
    end
    
    it "should be valid if value == 42" do
      i = Item.new(:number => 42)
      i.should be_valid
      i.errors.messages.should be_empty
    end
    
    it "should not be valid if value > 42" do
      i = Item.new(:number => 43)
      i.should_not be_valid
      i.errors.messages.should == [ "number must be less than or equal to 42" ]
    end
  end
  
  describe "should respect :odd" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :oddnumber, :odd => true
      end
    end
    
    it "should raise ArgumentError when argument is not true" do
      lambda do
        Meta.new { validates_numericality_of :number, :odd => :really? }
      end.should raise_error(ArgumentError)
    end
    
    it "should be valid when value is odd" do
      i = Item.new(:oddnumber => 1)
      i.should be_valid
      i.errors.messages.should be_empty
    end
    
    it "should not be valid when value is even" do
      i = Item.new(:oddnumber => 2)
      i.should_not be_valid
      i.errors.messages.should == [ "oddnumber must be odd" ]
    end
  end
  
  describe "should respect :even" do
    before :each do
      Item = Meta.new do
        validates_numericality_of :evennumber, :even => true
      end
    end
    
    it "should raise ArgumentError when argument is not true" do
      lambda do
        Meta.new { validates_numericality_of :number, :even => :really? }
      end.should raise_error(ArgumentError)
    end
      
    it "should be valid when value is even" do
      i = Item.new(:evennumber => 4)
      i.should be_valid
      i.errors.messages.should be_empty
    end
    
    it "should not be valid when value is odd" do
      i = Item.new(:evennumber => 1)
      i.should_not be_valid
      i.errors.messages.should == [ "evennumber must be even" ]
    end
  end

  it "should respect :allow_nil" do
    Meta.new(:name => 'some') { validates_numericality_of :number, :allow_nil => true }.new.should be_valid
  end

  describe "should allow for option combinations" do
    it ":less_than and :greater_than" do
      Item = Meta.new do
        validates_numericality_of :number, :less_than => 100, :greater_than => 50
      end

      Item.new(:number => 60).should be_valid
      
      i1 = Item.new(:number => 40)
      i1.should_not be_valid
      i1.errors.messages.should == [ "number must be greater than 50" ]

      i2 = Item.new(:number => 150)
      i2.should_not be_valid
      i2.errors.messages.should == [ "number must be less than 100" ]
    end

    it ":even and :less_than_or_equal_to" do
      Item = Meta.new do
        validates_numericality_of :number, :less_than_or_equal_to => 100, :even => true
      end
      
      Item.new(:number => 60).should be_valid
      
      i1 = Item.new(:number => 111)
      i1.should_not be_valid
      i1.errors.messages.sort.should == ["number must be less than or equal to 100", "number must be even"].sort
    end
  end
end

describe "Complex validations" do
  it "should gather errors for all slots"
  it "should run all validations for the same slot"
  it "should run all validations from all metas"
  it "should somehow deal with the case when different metas contain same validations types for the same slot"
end

describe "Meta with validation enabled" do
  before(:each) do
    validations_setup
    User = Meta.new { validates_uniqueness_of :email }
  end
  
  it "should be able to find instances of all documents" do
    doc = User.create! :email => "yrashk@gmail.com"
    User.find.should == [doc]
  end
end
