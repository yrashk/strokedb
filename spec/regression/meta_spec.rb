require File.dirname(__FILE__) + '/spec_helper'

describe "Adding meta" do
  
  before(:all) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'User') if defined?(User)
    Object.send!(:remove_const,'Buyer') if defined?(Buyer)
    User = StrokeDB::Meta.new
    Buyer = StrokeDB::Meta.new
    @user = User.create!
  end
  
  it "and saving document should not alter list of actual metas" do
    @user.metas << Buyer
    metas = @user[Meta].map{|v| v.to_raw }
    @user.save!
    @user[Meta].map{|v| v.to_raw }.should == metas
  end

  
end