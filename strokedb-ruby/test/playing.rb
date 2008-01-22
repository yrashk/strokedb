require 'strokedb'

store = StrokeDB::FileStore.new "db"
_d = nil
100.times do |i|
  _d1 = store.new_doc :welcome => 1
  _d = store.new_doc :hello => "once#{i}", :__meta__ => "Beliberda", :_d1 => _d1
  _d.save!
  _d1.save!
end

puts "last saved:"
d_ = store.find(_d.uuid)
puts store.send!(:filename,_d.uuid)
puts d_
d_[:something] = 1
d_.save!
puts d_
puts "----"
d_[:something_else] = 2
d_.save!
puts d_
puts d_[:_d1]
puts d_.previous_versions.inspect

puts "replica::::"
r = store.new_replica
r.replicate!(d_)
# puts r
d_[:wonderful] = "hello"
d_.save!
puts d_
puts store.find(d_.uuid)
r.update_replications!
puts ":::-----"
puts r.to_json(:transmittal => true)
puts "[[[[[[[]]]]]]]"
puts r.to_packet(:join => true)
puts "----------"
puts r
puts r[d_.uuid].member?(d_.version)
r.replicate!(d_)
puts r
r.replicate!(d_)
puts r
d_[:awonderful] = "hello"
d_.save!
r.replicate!(d_)
puts r
