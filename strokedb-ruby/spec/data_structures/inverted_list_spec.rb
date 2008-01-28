require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
 
describe InvertedList, " with flat string attributes" do
  
  def new_doc(meta, slots)
    slots[:__meta__] = meta
    slots[:__version__] = 'v1' + rand(10000000).to_s
    {:uuid => meta + rand(1000000).to_s, :slots => slots}
  end
  
  def insert_doc(il, doc)
    il.insert(doc[:slots], doc[:uuid])
  end
  
  before(:all) do
    @il = InvertedList.new
    @oleg_profile   = new_doc('Profile', :name   => 'Oleg',
                                         :email  => 'oleganza')
    @yrashk_profile = new_doc('Profile', :name   => 'Yurii', 
                                         :email  => 'yrashk')
    @article1       = new_doc('Article', :title  => 'StrokeDB kicks ass', 
                                         :author => ('#@' + @yrashk_profile[:uuid]))
    @article2       = new_doc('Article', :title  => 'StrokeDB strikes back', 
                                         :date   => '28 Jan 2008',
                                         :author => ('#@' + @yrashk_profile[:uuid]))
    @post1          = new_doc('Post',    :title  => 'Hello', 
                                         :date   => '28 Jan 2008',
                                         :author => ('#@' + @yrashk_profile[:uuid]))
    
    insert_doc(@il, @oleg_profile)
    insert_doc(@il, @yrashk_profile)
    insert_doc(@il, @article1)
    insert_doc(@il, @article2)
    insert_doc(@il, @post1)
  end
  
  it "should find objects by a single attribute" do
    @il.find(:name => 'Oleg').should == [@oleg_profile[:uuid]].to_set
    @il.find(:email => 'yrashk').should == [@yrashk_profile[:uuid]].to_set
    @il.find(:__meta__ => 'Article').should == [@article1[:uuid], @article2[:uuid]].to_set
    @il.find(:__version__ => @article1[:slots][:__version__]).should == [@article1[:uuid]].to_set
  end
  
  it "should not find object by a non-matched attribute" do
    @il.find(:name => 'Nobody').should == [  ].to_set
    @il.find(:__meta__ => 'NoMeta').should == [  ].to_set
    @il.find(:__version__ => 'no-version').should == [  ].to_set
  end
  
  it "should find objects by a pair of attributes" do
    @il.find(:date => '28 Jan 2008', :title => 'Hello').should == [@post1[:uuid]].to_set
    @il.find(:date => '28 Jan 2008', :__meta__ => 'Article').should == [@article2[:uuid]].to_set
    @il.find(:date => '28 Jan 2008', :author => ('#@' + @yrashk_profile[:uuid])).should == [@post1[:uuid], @article2[:uuid]].to_set
  end
  
  it "should not find objects by a not-matched pair of attributes" do
    @il.find(:date => '28 Jan 2008', :title => 'StrokeDB kicks ass').should == [  ].to_set
    @il.find(:date => '28 Jan 2008', :__meta__ => 'Profile').should == [  ].to_set
    @il.find(:date => '28 Jan 2008', :author => ('#@' + @oleg_profile[:uuid])).should == [  ].to_set
  end
  
  
end
