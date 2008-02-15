require 'strokedb'

# module StrokeDB
#   class << Util
#     def sha(str)
#       Digest::SHA256.hexdigest(str)[0..8]
#     end
#   end
# end

mem_storage = StrokeDB::MemoryChunkStorage.new 
file_storage = StrokeDB::FileChunkStorage.new :path => "test/storages/some_path_playing"
file_storage.clear!
store = StrokeDB::SkiplistStore.new :storage => mem_storage
mem_storage.add_chained_storage!(file_storage)

_d = nil
25.times do |i|
  puts i
  _d1 = StrokeDB::Document.new(store, :welcome => 1)
  _d = StrokeDB::Document.new(store, :hello => "once#{i}", :__meta__ => "Beliberda", :_d1 => _d1)
  _d.save!
  _d1.save!
end

puts "last saved (#{_d.uuid}):"
d_ = store.find(_d.uuid)
puts d_
d_[:something] = 1
d_.save!
puts d_
puts "----"
puts d_.uuid
d_[:something_else] = 2
d_.save!
puts d_
puts d_[:_d1]
puts d_.__previous_version__.inspect

puts "replica::::"
r = store.new_replica
r.sync_chained_storage!(d_)
# puts r
d_[:wonderful] = "hello"
d_.save!
puts d_
puts store.find(d_.uuid)
r.update_replications!
puts ":::-----"
puts r.to_json(:transmittal => true)
puts "[[[[[[[]]]]]]]"
puts r.to_packet
puts "----------"
puts r
puts r[d_.uuid].member?(d_.__version__)
r.sync_chained_storage!(d_)
puts r
r.sync_chained_storage!(d_)
puts r
d_[:awonderful] = "hello"
d_.save!
r.sync_chained_storage!(d_)
puts r
mem_storage.sync_chained_storages!
