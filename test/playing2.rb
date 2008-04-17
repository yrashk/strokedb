$:.unshift File.dirname(__FILE__) + "/.."
require "strokedb"

config = StrokeDB::Config.build :default => true, :base_path => 'test/storages/playing2'

Email = StrokeDB::Meta.new
User = StrokeDB::Meta.new do
  #validates_type_of :email, :as => :string
end
unless u = User.find(:email => "yrashk@gmail.com").first
  puts "User not found, creating new user"
  u = User.create! :email => "yrashk@gmail.com"
else
  puts "We've found him!"
end

v = User.create! :email => "yrashk@gmail.com"

a = User.find(:email => "yrashk@gmail.com").is_a? Array
p a
p a.size

au = User.create! :email => "#{rand(100)}@gmail.com"
puts u

view = StrokeDB::View.find_or_create(:name => "all users").reduce_with{|doc| doc.is_a?(User) }

puts view.uuid
puts view.emit.to_raw.to_json

config[:memory_chunk].sync_chained_storages!
