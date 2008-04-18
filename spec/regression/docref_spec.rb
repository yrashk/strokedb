require File.dirname(__FILE__) + '/spec_helper'

describe 'DocRef' do

  before(:each) do
    @path = TEMP_STORAGES + '/docref_reg'
    FileUtils.rm_rf @path
    StrokeDB::Config.build :default => true, :base_path => @path
    Object.send!(:remove_const,'T') if defined?(T)
    T = StrokeDB::Meta.new do
      on_new_document do |doc|
        doc.children = []
        doc.parent = nil
      end

      def add_child c
        # unless children.find{ |d| d.uuid == c.uuid } # works
        unless children.include?(c) # XXX doesn't work
          children << c
          save!
        end
      end
    end
  end

  it 'should add children' do
    a = T.find_or_create :name => 'a'
    b = T.find_or_create :name => 'b'

    a.children.size.should == 0
    a.children.should_not include(b)

    a.add_child b

    a.children.size.should == 1
    a.children.should include(b)
  end

  it 'should not add child if exists' do
    a = T.find_or_create :name => 'a'
    b = T.find_or_create :name => 'b'
    c = T.find_or_create :name => 'c'

    a.add_child b

    a.children.size.should == 1
    a.children.should include(b)

    a.add_child b

    a.children.size.should == 1
    a.children.should include(b)
    

    b.add_child c

    a.children.should include(b)
    a.children.should_not include(b.extend(VersionedDocument))
    
    b.children.should include(c)
  end

  it 'should work with -' do
    a = T.find_or_create :name => 'a'
    b = T.find_or_create :name => 'b'

    a.add_child b

    a = T.find_or_create :name => 'a'
    b = T.find_or_create :name => 'b'

    ([a, b] - [a, b]).should == []
    #a.children.reject{|c| [b].include?(c) }.should == [] # old workaround
    (a.children - [b]).should == []
  end

  it 'should work after re-opening database' do
    a = T.find_or_create :name => 'a'
    b = T.find_or_create :name => 'b'

    a.add_child b

    StrokeDB.default_store.stop_autosync!
    StrokeDB::Config.build :default => true, :base_path => @path

    a = T.find_or_create :name => 'a'
    b = T.find_or_create :name => 'b'

    a.children.size.should == 1
    #a.children.find{ |d| d.uuid == b.uuid }.should_not be_nil # old workaround
    a.children.should include(b)
  end

end