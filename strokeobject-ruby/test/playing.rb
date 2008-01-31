$:.unshift File.dirname(__FILE__) + "/../../strokedb-ruby"
$:.unshift File.dirname(__FILE__) + "/.."
require "strokeobject"



@mem = StrokeDB::MemoryChunkStorage.new
@fs = StrokeDB::FileChunkStorage.new "test/storages/test"
@mem.add_chained_storage!(@fs)
@mem.authoritative_source=@fs
index_storage = StrokeDB::InvertedListFileStorage.new('test/storages/inverted_list_storage')
# index_storage.clear!
@index = StrokeDB::InvertedListIndex.new(index_storage)
Stroke.default_store = StrokeDB::SkiplistStore.new(@mem,6, @index)
@index.document_store = Stroke.default_store
Stroke::Meta.new(:name => "User")
unless u = @index.find(:__meta__ => User.document, :email => "yrashk@gmail.com").first
  puts "User not found, creating new user"
  u = User.new :email => "yrashk@gmail.com"
  u.save!
else
  puts "We've found him!"
end
puts u

@mem.sync_chained_storages!

 



