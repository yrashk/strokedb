require File.dirname(__FILE__) + '/spec_helper'

describe "Document" do

  before(:each) do
    setup_default_store
    Object.send!(:remove_const,'SomeMeta') if defined?(SomeMeta)
    SomeMeta = Meta.new
    @document = Document.new
  end

  it "should assign a uuid-named slot for metaslot" do
    @document[Meta] = SomeMeta
    @document.slotnames.should include(Meta.document.uuid)
  end

  it "should assign a uuid-named slot for metaslot" do
    @document[SomeMeta] = "some value"
    @document.slotnames.should include(SomeMeta.document.uuid)
  end

  it "should be able to read metaslot" do
    @document[SomeMeta] = "some value"
    @document[SomeMeta].should == "some value"
  end
  
  describe "with metaslot assigned, once saved and reloaded" do
    
    before(:each) do
      @document[SomeMeta] = "some value"
      @document.save!
      @document = @document.reload
    end
    
    it "should be able to read metaslot" do
      @document[SomeMeta].should == "some value"
    end
    
  end
  
  

end