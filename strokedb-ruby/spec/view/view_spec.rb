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
    # vd = @view.documents.sort_by {|z| z.version}
    # d = (@documents + [Meta.document,View.document]).sort_by {|z| z.version}
    # vd.each_with_index do |vde,i|
    #   puts "#{i} #{vde == d[i]}"
    #   unless vde == d[i]
    #     puts "mismatch: #{vde} #{d[i]} // #{vde.uuid} #{d[i].uuid}" 
    #     puts "#{vde.class} #{d[i].class}"
    #   end
    # end
    @view.documents.sort_by {|doc| doc.uuid}.should == (@documents + [Meta.document,View.document]).sort_by {|doc| doc.uuid}
    # @view.documents.to_set.should == (@documents + [Meta.document,View.document]).to_set
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
    @view.documents.sort_by {|doc| doc.nil? ? "0" : doc.uuid}.should == (@documents + [nil,nil]).sort_by {|doc| doc.nil? ? "0" :  doc.uuid}
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
    @view.documents(:i).sort_by {|doc| doc.nil? ? "0" : doc.uuid}.should == (@documents + [nil,nil]).sort_by {|doc| doc.nil? ? "0" :  doc.uuid}
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
    @view.documents.sort_by {|doc| doc.uuid}.should == @documents.sort_by {|doc| doc.uuid}
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
    @view.documents.sort_by {|doc| doc.uuid}.should == @documents.sort_by {|doc| doc.uuid}
  end

end