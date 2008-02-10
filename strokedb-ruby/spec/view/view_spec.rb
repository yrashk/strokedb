require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "View without map_with and reduce_with blocks" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "without block")
  end

  it "should return all documents plus Meta and View" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.sort_by {|doc| doc.uuid}.should == (@documents + [Meta.document,View.document]).sort_by {|doc| doc.uuid}
  end

end

describe "View with map_with (without extra arguments)" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with map_with (without extra arguments)") {|doc| doc.slotnames.include?('i') ? doc : nil}
  end

  it "should return all documents plus two nils" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.sort_by {|doc| doc.nil? ? "0" : doc.uuid}.should == (@documents + [nil,nil]).sort_by {|doc| doc.nil? ? "0" :  doc.uuid}
  end

end

describe "View with map_with (with extra arguments)" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with map_with (with extra arguments)") {|doc,slotname| doc.slotnames.include?(slotname.to_s) ? doc : nil}
  end

  it "should return all documents plus two nils" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit(:i).to_a.sort_by {|doc| doc.nil? ? "0" : doc.uuid}.should == (@documents + [nil,nil]).sort_by {|doc| doc.nil? ? "0" :  doc.uuid}
  end

end

describe "View with map_with and reduce_with" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with map_with and reduce_with") {|doc| doc.slotnames.include?('i') ? doc : nil}.reduce_with{|doc| !doc.nil? }
  end

  it "should return all documents" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.sort_by {|doc| doc.uuid}.should == @documents.sort_by {|doc| doc.uuid}
  end

end

describe "View with reduce_with" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with reduce_with").reduce_with{|doc| doc.slotnames.include?('i') }
  end

  it "should return all documents" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.sort_by {|doc| doc.uuid}.should == @documents.sort_by {|doc| doc.uuid}
  end

end

describe "View with reduce_with (with extra arguments)" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with reduce_with (with extra arguments)").reduce_with {|doc,slotname| doc.slotnames.include?(slotname.to_s) }
  end

  it "should return all documents plus two nils" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit(:i).to_a.sort_by {|doc| doc.uuid}.should == @documents.sort_by {|doc| doc.uuid}
  end

end

describe "View" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "incremental view").reduce_with{|doc| doc.slotnames.include?('i') }
  end

  it "should be able to return new documents incrementally" do
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    cut = @view.emit
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i+100)
    end
    cut.emit.to_a.sort_by {|doc| doc.uuid }.should == @documents.sort_by {|doc| doc.uuid }
  end

end