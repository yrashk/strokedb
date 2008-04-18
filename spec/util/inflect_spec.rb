require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/util/inflect')

describe "Inflect" do

  it "#singular should return singular of word" do
    English::Inflect.singular('boy').should == 'boy'
    English::Inflect.singular('boys').should == 'boy'
  end
  
  it "#prural should return plural of word" do
    English::Inflect.plural('hive').should == 'hives'
  end

end