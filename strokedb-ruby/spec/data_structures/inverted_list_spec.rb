require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
 
describe InvertedList, " with flat string attributes" do
  
  def new_doc(meta, slots)
    slots[:__meta__] = meta
    slots[:__version__] = 'v1' + rand(10000000).to_s
    {:uuid => rand(1000000).to_s, :slots => slots}
  end
  
  def insert_doc(il, doc)
    il.insert(doc[:slots], doc[:uuid])
  end
  
  before(:all) do
    @il = InvertedList.new
    @oleg_profile   = new_doc('Profile', :name  => 'Oleg',
                                         :email => 'oleganza')
    @yrashk_profile = new_doc('Profile', :name  => 'Yurii', 
                                         :email => 'yrashk')
    @article1       = new_doc('Article', :title => 'StrokeDB kicks ass', 
                                         :author => ('#@' + @yrashk_profile[:uuid]))
    @article2       = new_doc('Article', :title => 'StrokeDB strikes back', 
                                         :author => ('#@' + @yrashk_profile[:uuid]))
    insert_doc(@il, @oleg_profile)
    insert_doc(@il, @yrashk_profile)
    insert_doc(@il, @article1)
    insert_doc(@il, @article2)
  end
  
  it "should find objects by a single attribute" do
    @il.find(:name => 'Oleg').should == [@oleg_profile[:uuid]]
    @il.find(:email => 'yrashk').should == [@yrashk_profile[:uuid]]
    @il.find(:__meta__ => 'Article').to_set.should == [@article1[:uuid], @article2[:uuid]].to_set
    @il.find(:__version__ => @article1[:slots][:__version__]).to_set.should == [@article1[:uuid]].to_set
  end
  
end
