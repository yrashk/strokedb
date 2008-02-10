require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "View without map_with and reduce_with blocks" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "without block")
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
  end

  it "should return all documents plus Meta and View" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.sort_by {|doc| doc.__lamport_timestamp__}.should == (@documents + [Meta.document,View.document,ViewCut.document]).sort_by {|doc| doc.__lamport_timestamp__}
  end

end

describe "View with map_with (without extra arguments)" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with map_with (without extra arguments)") {|doc| doc.slotnames.include?('i') ? doc : nil}
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
  end

  it "should return all documents plus three nils" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.sort_by {|doc| doc.nil? ? "0" : doc.uuid}.should == (@documents + [nil,nil,nil]).sort_by {|doc| doc.nil? ? "0" :  doc.uuid}
  end

end

describe "View with map_with (with extra arguments)" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with map_with (with extra arguments)") {|doc,slotname| doc.slotnames.include?(slotname.to_s) ? doc : nil}
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
  end

  it "should return all documents plus three nils" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit(:i).to_a.sort_by {|doc| doc.nil? ? "0" : doc.uuid}.should == (@documents + [nil,nil,nil]).sort_by {|doc| doc.nil? ? "0" :  doc.uuid}
  end

end

describe "View with map_with and reduce_with" do

  before(:each) do
    setup_default_store
    setup_index
    @view = View.new(:name => "with map_with and reduce_with") {|doc| doc.slotnames.include?('i') ? doc : nil}.reduce_with{|doc| !doc.nil? }
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
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
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
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
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
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
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
  end

  it "should make documents VersionedDocuments" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    @view.emit.to_a.each {|d| d.should be_a_kind_of(VersionedDocument)}
  end
  
  it "should be able to return new documents incrementally" do
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i)
    end
    cut = @view.emit
    @documents = []
    10.times do |i|
      @documents << Document.create!(:i => i+100)
    end
    a = cut.emit.to_a
    a.sort_by {|doc| doc.uuid }.should == @documents.sort_by {|doc| doc.uuid }
    a.each {|d| d.should be_a_kind_of(VersionedDocument)} # make sure next emit produces VersionedDocuments as well
  end

end

describe "Newly created View" do
  
  before(:each) do
    setup_default_store
    setup_index
    @view = View.new
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
  end
  
  it "should reference first cut as last cut when it is saved" do
    cut = @view.emit
    cut.save!
    @view.last_cut.should == cut
  end
  
  it "save view on first cut save" do
    cut = @view.emit
    cut.save!
    @view.should_not be_new
  end
  
end

describe "View with cut(s) available" do
  
  before(:each) do
    setup_default_store
    setup_index
    @view = View.new
    ViewCut.document # this is to ensure that ViewCut document is created prior to emitting more data in cuts
    @cut = @view.emit
    @cut.save!
  end
  
  it "should refer to newly emitted cut as last cut (when it is saved)" do
    new_cut = @cut.emit
    @view.reload.last_cut.should == @cut
    new_cut.save!
    @view.reload.last_cut.should == new_cut
  end

  it "should not refer to newly emitted cut as last cut (when it is saved) if this cut isn't really last" do
    new_cut = @cut.emit
    new_cut.save!
    @view.reload.last_cut.should == new_cut
    another_cut = @cut.emit
    another_cut.save!
    @view.reload.last_cut.should == new_cut
  end
  
end