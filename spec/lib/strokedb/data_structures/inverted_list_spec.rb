require File.dirname(__FILE__) + '/spec_helper'
 
describe InvertedList, " with flat string attributes" do
  
  before(:all) do
    @il = InvertedList.new
    @oleg_profile   = new_doc('Profile', :name   => 'Oleg',
                                         :email  => 'oleganza')
    @yrashk_profile = new_doc('Profile', :name   => 'Yurii', 
                                         :email  => 'yrashk')
    @article1       = new_doc('Article', :title  => 'StrokeDB kicks ass', 
                                         :author => ('@#' + @yrashk_profile[:uuid]))
    @article2       = new_doc('Article', :title  => 'StrokeDB strikes back', 
                                         :date   => '28 Jan 2008',
                                         :author => ('@#' + @yrashk_profile[:uuid]))
    @post1          = new_doc('Post',    :title  => 'Hello', 
                                         :date   => '28 Jan 2008',
                                         :author => ('@#' + @yrashk_profile[:uuid]))
    
    insert_doc(@il, @oleg_profile)
    insert_doc(@il, @yrashk_profile)
    insert_doc(@il, @article1)
    insert_doc(@il, @article2)
    insert_doc(@il, @post1)
  end
  
  it "should find objects by a single attribute" do
    @il.find(:name => 'Oleg').should == [@oleg_profile[:uuid]].to_set
    @il.find(:email => 'yrashk').should == [@yrashk_profile[:uuid]].to_set
    @il.find(:meta => 'Article').should == [@article1[:uuid], @article2[:uuid]].to_set
    @il.find(:version => @article1[:slots][:version]).should == [@article1[:uuid]].to_set
  end
  
  it "should not find object by a not matched attribute" do
    @il.find(:name => 'Nobody').should == [  ].to_set
    @il.find(:meta => 'NoMeta').should == [  ].to_set
    @il.find(:version => 'no-version').should == [  ].to_set
  end
  
  it "should find objects by a pair of attributes" do
    @il.find(:date => '28 Jan 2008', :title => 'Hello').should == [@post1[:uuid]].to_set
    @il.find(:date => '28 Jan 2008', :meta => 'Article').should == [@article2[:uuid]].to_set
    @il.find(:date => '28 Jan 2008', :author => ('@#' + @yrashk_profile[:uuid])).should == [@post1[:uuid], @article2[:uuid]].to_set
  end
  
  it "should not find objects by a not matched pair of attributes" do
    @il.find(:date => '28 Jan 2008', :title => 'StrokeDB kicks ass').should == [  ].to_set
    @il.find(:date => '28 Jan 2008', :meta => 'Profile').should == [  ].to_set
    @il.find(:date => '28 Jan 2008', :author => ('@#' + @oleg_profile[:uuid])).should == [  ].to_set
  end
  
  it "should find objects by three attributes" do
    @il.find(:date     => '28 Jan 2008', 
             :author   => ('@#' + @yrashk_profile[:uuid]),
             :meta => 'Article'
             ).should == [ @article2[:uuid] ].to_set
  end
  
  it "should not find objects by not matched three attributes" do
    @il.find(:date     => '28 Jan 2008', 
             :author   => ('@#' + @oleg_profile[:uuid]),
             :meta => 'Article'
             ).should == [   ].to_set
    @il.find(:date     => '42 Jan 2008', 
             :author   => ('@#' + @yrashk_profile[:uuid]),
             :meta => 'Article'
             ).should == [   ].to_set
    @il.find(:date     => '28 Jan 2008', 
             :author   => ('@#' + @yrashk_profile[:uuid]),
             :meta => 'Profile'
             ).should == [   ].to_set
  end
  
  it "should delete doc from index" do
    @il.find(:name => 'Oleg').should == [@oleg_profile[:uuid]].to_set
    delete_doc(@il, @oleg_profile)
    @il.find(:name => 'Oleg').should == [  ].to_set
    @il.find(:email => 'yrashk').should == [@yrashk_profile[:uuid]].to_set
    delete_doc(@il, @yrashk_profile)
    @il.find(:email => 'yrashk').should == [  ].to_set
  end
  
end

describe InvertedList, " with numeric attributes" do
  
  before(:all) do
    @il = InvertedList.new
    @ps = []
    @ps << new_doc('Point', :x =>    0, :y =>  0)   # 0 
    @ps << new_doc('Point', :x =>   10, :y =>  50)  # 1
    @ps << new_doc('Point', :x =>   50, :y =>  50)  # 2
    @ps << new_doc('Point', :x =>  200, :y =>  10)  # 3
    @ps << new_doc('Point', :x =>  500, :y =>  10)  # 4
    @ps << new_doc('Point', :x => -500, :y =>  10)  # 5
    @ps << new_doc('Point', :x =>  -20, :y =>  10)  # 6
    @ps << new_doc('Point', :x => -2.1, :y =>  10)  # 7
    @ps << new_doc('Point', :x => 20.6, :y =>  10)  # 8
    
    @ps.each {|p| insert_doc(@il, p) }
  end
  
  it "should find by positive value" do
    @il.find(:x =>  10).should == [@ps[1][:uuid]].to_set
    @il.find(:x =>  50).should == [@ps[2][:uuid]].to_set
    @il.find(:x => 200).should == [@ps[3][:uuid]].to_set
  end
  
  it "should find by negative value" do
    @il.find(:x => -500).should == [@ps[5][:uuid]].to_set
    @il.find(:x =>  -20).should == [@ps[6][:uuid]].to_set
  end

  it "should find by zero value" do
    @il.find(:x => 0).should == [@ps[0][:uuid]].to_set
  end
  
  # Dangerous: 2.1 may suddenly appear as 2.0999999999996235 or like that
  it "should find by float value" do
    @il.find(:x => -2.1).should == [@ps[7][:uuid]].to_set
    @il.find(:x => 20.6).should == [@ps[8][:uuid]].to_set
  end
  
end
=begin
describe InvertedList, " with multivalue slots" do
  before(:all) do
    @il = InvertedList.new
    @ab   = new_doc(%w[A B])
    @a    = new_doc(%w[A])
    @b    = new_doc(%w[B])
    @c    = new_doc(%w[C])
    insert_doc(@il, @ab)
    insert_doc(@il, @a)
    insert_doc(@il, @b)
    insert_doc(@il, @c)
  end
  
  it "should find multivalue objects by a single value" do
    @il.find(:meta => proc{|v| v.include? 'A' }).should == [@a[:uuid], @ab[:uuid]].to_set
    @il.find(:meta => proc{|v| v.include? 'B' }).should == [@b[:uuid], @ab[:uuid]].to_set
  end
  
  it "should not find by scalar value" do
    @il.find(:meta => 'A').should == [ ].to_set
    @il.find(:meta => 'B').should == [ ].to_set
  end
  
  it "should find multivalue objects with a complex predicate" do
    @il.find(:meta => proc{|v| v.include?('A') && !v.include?('B') }).should == [@a[:uuid]].to_set
    @il.find(:meta => proc{|v| v.include?('A') || v.include?('B') }).should == 
      [@a[:uuid], @ab[:uuid], @b[:uuid]].to_set
    @il.find(:meta => proc{|v| v.include?('A') && v.include?('B') }).should == [@ab[:uuid]].to_set
  end
end
=end


def new_doc(meta, slots = {})
  slots[:meta] = meta
  slots[:version] = 'v1' + rand(10000000).to_s
  {:uuid => meta.to_s + '-' + rand(1000000).to_s, :slots => slots}
end

def insert_doc(il, doc)
  il.insert(doc[:slots], doc[:uuid])
end

def delete_doc(il, doc)
  il.delete(doc[:slots], doc[:uuid])
end

