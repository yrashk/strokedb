describe "Meta module with on_initialization callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      on_initialization do |obj|
        Kernel.send!(:on_initialization_called,obj.new?)
      end
    end
  end
  
  it "should receive this callback on meta instantiation" do
    Kernel.should_receive(:on_initialization_called).with(true)
    doc = SomeName.new
  end
  
  it "should be a sole meta receiving this callback when adding metas dynamically" do
    Object.send!(:remove_const,'SomeOtherName') if defined?(SomeOtherName)
    SomeOtherName = Meta.new do
      on_initialization do |obj|
        Kernel.send!(:other_on_initialization_called,obj.new?)
      end
    end
    Kernel.should_receive(:other_on_initialization_called).with(true).once
    doc = SomeOtherName.new
    Kernel.should_receive(:on_initialization_called).with(true).once
    doc.metas << SomeName
  end
  
end


describe "Meta module with on_load callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      on_load do |obj|
        Kernel.send!(:on_load_called,obj.new?)
      end
    end
  end
  
  it "should not receive this callback on meta instantiation" do
    Kernel.should_not_receive(:on_load_called)
    doc = SomeName.new
  end

  it "should receive this callback on document load" do
    doc = SomeName.create!
    Kernel.should_receive(:on_load_called).with(false)
    d = SomeName.find(doc.uuid)
  end
  
  
end

describe "Meta module with before_save callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      before_save do |obj|
        Kernel.send!(:before_save_called,obj.new?)
      end
    end
  end
  
  it "should initiate callback on Document#save! (before actually saving it)" do
    s = SomeName.new
    Kernel.should_receive(:before_save_called).with(true)
    s.save!
  end

end

describe "Meta module with after_save callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      after_save do |obj|
        Kernel.send!(:after_save_called,obj.new?)
      end
    end
  end
  
  it "should initiate callback on Document#save! (after actually saving it)" do
    s = SomeName.new
    Kernel.should_receive(:after_save_called).with(false)
    s.save!
  end

end


describe "Meta module with on_new_document callback" do
  
  before(:each) do
    setup_default_store
    setup_index
    
    Object.send!(:remove_const,'SomeName') if defined?(SomeName)
    SomeName = Meta.new do
      on_new_document do |obj|
        Kernel.send!(:on_new_document,obj.new?)
      end
    end
  end
  
  it "should initiate callback on Document#new" do
    Kernel.should_receive(:on_new_document).with(true)
    s = SomeName.new
  end

  it "should not initiate callback on loaded Document" do
    Kernel.should_receive(:on_new_document).with(true).once
    s = SomeName.new
    s.save!
    s.reload
  end

end
