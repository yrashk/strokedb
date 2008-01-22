require File.dirname(__FILE__) + '/spec_helper'

module ReplicaSpecHelper
  
  def avoid_replica_from_being_saved
    @replica.stub!(:save!) # this way we're avoiding replica from being actually saved, which is out of this spec's scope
  end
  
end

describe "Replica with no replications" do

  include ReplicaSpecHelper
  
  before(:each) do
    @store = mock("Store")
    @document = mock("Document")
    @document.stub!(:uuid).and_return '34b030ab-03a5-4d97-a08a-a7b27daf0897'
    @replica = Replica.new(@store)
    avoid_replica_from_being_saved
  end
  
  it "should add all Document's versions" do
    @document.stub!(:all_versions).and_return ['81f153775c952bd1144e118c1b6daa427aa60c6082265d87cc12703a9070040c',
                                               'ebfa015966891a400bf353bdf8ef30444a71b1751e2808ef6c014db34d168d85',
                                               '80d8f975e768eecac59d22a788bf8e811e51ca85e309ee47f1e821e3e58280f2']
    @replica.replicate!(@document)                                                    
    @replica[@document.uuid].should == @document.all_versions
  end

  
end

describe "Replica with document being replicated once" do
  
  include ReplicaSpecHelper
  
  before(:each) do
    @store = mock("Store")
    @document = mock("Document")
    @document.stub!(:uuid).and_return '34b030ab-03a5-4d97-a08a-a7b27daf0897'
    @store.should_receive(:find).with(@document.uuid).any_number_of_times.and_return(@document)
    @replica = Replica.new(@store)
    avoid_replica_from_being_saved
    @document.stub!(:all_versions).and_return ['81f153775c952bd1144e118c1b6daa427aa60c6082265d87cc12703a9070040c',
                                               'ebfa015966891a400bf353bdf8ef30444a71b1751e2808ef6c014db34d168d85',
                                               '80d8f975e768eecac59d22a788bf8e811e51ca85e309ee47f1e821e3e58280f2']
    @replica.replicate!(@document)                                                    
  end
  
  it "should create empty replication on #replicate! for the same document if it was unchanged" do
    @replica.replicate!(@document)
    @replica[@document.uuid].should == []
  end

  it "should create empty replication on #update_replications! for the same document if it was unchanged" do
    @replica.update_replications!
    @replica[@document.uuid].should == []
  end
  
  it "should add only new versions of document on #replicate! if document was changed" do
    @document.stub!(:all_versions).and_return ['4c46afd3248b71d03cfc4e0ff693244cad02c2a5e0cfc1cb105de4c6b3cae78a',
                                               '81f153775c952bd1144e118c1b6daa427aa60c6082265d87cc12703a9070040c',
                                               'ebfa015966891a400bf353bdf8ef30444a71b1751e2808ef6c014db34d168d85',
                                               '80d8f975e768eecac59d22a788bf8e811e51ca85e309ee47f1e821e3e58280f2']
    @replica.stub!(:previous_versions).and_return []
    @replica.replicate!(@document)
    @replica[@document.uuid].should == ['4c46afd3248b71d03cfc4e0ff693244cad02c2a5e0cfc1cb105de4c6b3cae78a']
  end
  
  it "should add only new versions of document on #update_replications! if document was changed" do
    @document.stub!(:all_versions).and_return ['4c46afd3248b71d03cfc4e0ff693244cad02c2a5e0cfc1cb105de4c6b3cae78a',
                                               '81f153775c952bd1144e118c1b6daa427aa60c6082265d87cc12703a9070040c',
                                               'ebfa015966891a400bf353bdf8ef30444a71b1751e2808ef6c014db34d168d85',
                                               '80d8f975e768eecac59d22a788bf8e811e51ca85e309ee47f1e821e3e58280f2']
    @replica.stub!(:previous_versions).and_return []
    @replica.update_replications!
    @replica[@document.uuid].should == ['4c46afd3248b71d03cfc4e0ff693244cad02c2a5e0cfc1cb105de4c6b3cae78a']
  end
  
end