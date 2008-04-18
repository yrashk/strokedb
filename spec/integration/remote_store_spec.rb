require File.dirname(__FILE__) + '/spec_helper'
=begin
class RemoteStoreContext
  def initialize(store)
    @user = Meta.new store, :name => "User"
  end
  def create_user(*args)
    @user.create!(*args)
  end
  def find_users
    @user.find
  end
end

class ClientScenario < RemoteStoreContext 
  def initialize
    @store = StrokeDB::RemoteStore::Client.new('127.0.0.1', 4440)
    super(@store)
  end
end

class ServerScenario < RemoteStoreContext 
  def initialize
    StrokeDB::Config.build :default => true, :base_path => '../temp/storages/drb_store'
    StrokeDB.default_store.remote_server("0.0.0.0", 4540).start
    super(StrokeDB.default_store)
  end
end
Thread.abort_on_exception = true
server_thread = Thread.new{ Thread.current['s'] = ServerScenario.new }
client_thread = Thread.new{ Thread.current['s'] = ClientScenario.new }

sleep 2
p server_thread['s'].create_user(:name => "server guy")
exit!

describe "Database operations thru remote_store" do

  it "should work perfectly" do
    # Start scenarios
    client = $client
    server = $server
    
    # 1. Store document on a server
    server.create_user(:name => "server guy").name.should == 'server guy'
    server.find_users.size.should == 1
    server.find_users[0].name.should == 'server guy'
    
    # 2. Find server's documents in a client
    client.find_users.size.should == 1
    server.find_users[0].name.should == 'server guy'
    
    # 3. Store document on a client
    client.create_user(:name => "client guy").name.should == 'client guy'
    
    # 4. Find all the documents on a server
    server.find_users.size.should == 2
    server.find_users[0].name.should == 'server guy'
    server.find_users[1].name.should == 'client guy'
    
    # 5. Find all documents in a client
    client.find_users.size.should == 2
    client.find_users[0].name.should == 'server guy'
    client.find_users[1].name.should == 'client guy'
  end

end  
  
=end

