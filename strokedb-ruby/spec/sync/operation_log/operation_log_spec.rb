require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "OperationLog examples" do
  before(:each) do
    @storage = MemoryChunkStorage.new
    @oplog   = OperationLog.new(@storage)
  end
  
=begin

Operations:
  create
  delete
  patch
  transaction

Doc level:
  create:        Document.create! or doc.save!
  delete:        doc.delete!
  patch:         doc.slot = 1; doc.save!
  transaction:   some_transaction = Transaction.find_or_create(:name => "some descriptive info") do |a, b| 
                   a.balance += 1
                   b.balance -= 1
                 end
                 some_transaction.new(a, b).execute!

=end
  
  it "should " do
    
    
    
  end
end
