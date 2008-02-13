$:.unshift File.dirname(__FILE__) + "/.."
require "strokedb"

config = StrokeDB::Config.new(true)

config.add_storage :mem, :memory_chunk
config.add_storage :fs, :file_chunk, 'test/storages/test'

config.chain :mem, :fs
config[:mem].authoritative_source = config[:fs]

config.add_storage :index_storage, :inverted_list_file, 'test/storages/index'
config.add_index :default, :inverted_list, :index_storage

config.add_store :default, :skiplist, :mem, :cut_level => 4


User = StrokeDB::Meta.new
unless u = User.find(:email => "yrashk@gmail.com").first
  puts "User not found, creating new user"
  u = User.create! :email => "yrashk@gmail.com"
else
  puts "We've found him!"
end

au = User.create! :email => "#{rand(100)}@gmail.com"
puts u

view = StrokeDB::View.find_or_create(:name => "all users").reduce_with{|doc| doc.is_a?(User) }
puts view.uuid
puts view.emit.to_json

config[:mem].sync_chained_storages!

 



