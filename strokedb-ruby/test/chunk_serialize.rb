require 'strokedb'
require 'pp'
include StrokeDB

=begin 
   # weird raw chunked skiplists test
   
all_lists = {}
nextlist = Skiplist.new({},nil,3)
100.times do |i|
  a,b = nextlist.insert("K#{i+100}","V")
  nextlist = b || a 
  [a,b].each do |c|
    all_lists[c.head.forward[0].key] = c if c
  end
end

all_lists.each do |k,l|
puts k
  puts l.to_s_levels
  puts "------"
end
exit
=end

fs = FileStore.new "test/storages/some-path"

head_chunk = Chunk.new(3)

all_chunks = {} # uuid => chunk
20.times do |i|
  doc = Document.new(fs, :some_data => i)
  a, b = head_chunk.insert("K#{100+i}", doc.to_raw)
  head_chunk = b || a
  [a, b].each do |c|
    all_chunks[c.uuid] = c if c
  end
end

all_chunks.each{|k,v|
 rawv = v.to_raw
 pp [k, rawv]
 object = Chunk.from_raw(rawv)
 object.next_chunk = all_chunks[rawv['next_uuid']]
 pp [k, object.to_raw]
 pp rawv == object.to_raw 
 puts "------"
 #puts v.skiplist.to_s
}

#pp head_chunk.to_raw

=begin


~/Experiments/Ruby/strokedb/strokedb-ruby $ ruby test/chunk_serialize.rb 
["K102",
 {"cut_level"=>3,
  "uuid"=>"K102",
  "next_uuid"=>"K109",
  "nodes"=>
   [{"forward"=>[1, 3, 0, 0],
     "value"=>
      {"__version__"=>
        "6d1dc31dd3b26c15c96e15615e08b49814677a1b7701784e4236fc930ebe460e",
       "some_data"=>2},
     "key"=>"K102"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "5899a8b229a25b01db929a25cdf7214edcde6507cc28dc7bccb53d422ec3d89f",
       "some_data"=>3},
     "key"=>"K103"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "8526d1d9784d89a13e42289ef068ff8066966af0c7712a81a0b995cf6fd5564b",
       "some_data"=>4},
     "key"=>"K104"},
    {"forward"=>[4, 0],
     "value"=>
      {"__version__"=>
        "59ffed01bea1ec0b6aa818eb5beb6d95fa58aa1cb8c3cf8740c5375faab6acf6",
       "some_data"=>5},
     "key"=>"K105"},
    {"forward"=>[5],
     "value"=>
      {"__version__"=>
        "e916f66fa5a0b0df29da7e1ef636a8ed60ce6fea96a5ec2f4e9560e21668c580",
       "some_data"=>6},
     "key"=>"K106"},
    {"forward"=>[6],
     "value"=>
      {"__version__"=>
        "cbbe0a809aa104784e691e6680c0df6f13c4e6171642daa96bb607aff627f7c2",
       "some_data"=>7},
     "key"=>"K107"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "e140c94e0b7f13926c37cc568072e159df028499c0f8ab6c3d792242a93a0600",
       "some_data"=>8},
     "key"=>"K108"}]}]
["K102",
 {"cut_level"=>3,
  "uuid"=>"K102",
  "next_uuid"=>"K109",
  "nodes"=>
   [{"forward"=>[1, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "6d1dc31dd3b26c15c96e15615e08b49814677a1b7701784e4236fc930ebe460e",
       "some_data"=>2},
     "key"=>"K102"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "5899a8b229a25b01db929a25cdf7214edcde6507cc28dc7bccb53d422ec3d89f",
       "some_data"=>3},
     "key"=>"K103"},
    {"forward"=>[3, 3],
     "value"=>
      {"__version__"=>
        "8526d1d9784d89a13e42289ef068ff8066966af0c7712a81a0b995cf6fd5564b",
       "some_data"=>4},
     "key"=>"K104"},
    {"forward"=>[4, 0],
     "value"=>
      {"__version__"=>
        "59ffed01bea1ec0b6aa818eb5beb6d95fa58aa1cb8c3cf8740c5375faab6acf6",
       "some_data"=>5},
     "key"=>"K105"},
    {"forward"=>[5],
     "value"=>
      {"__version__"=>
        "e916f66fa5a0b0df29da7e1ef636a8ed60ce6fea96a5ec2f4e9560e21668c580",
       "some_data"=>6},
     "key"=>"K106"},
    {"forward"=>[6],
     "value"=>
      {"__version__"=>
        "cbbe0a809aa104784e691e6680c0df6f13c4e6171642daa96bb607aff627f7c2",
       "some_data"=>7},
     "key"=>"K107"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "e140c94e0b7f13926c37cc568072e159df028499c0f8ab6c3d792242a93a0600",
       "some_data"=>8},
     "key"=>"K108"}]}]
false
------
["K116",
 {"cut_level"=>3,
  "uuid"=>"K116",
  "next_uuid"=>nil,
  "nodes"=>
   [{"forward"=>[1, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "afe33c9e81d85ea74d0682cd504c24cc858eaec63423c74553158d9cbe0aa51f",
       "some_data"=>16},
     "key"=>"K116"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "537eff6101dc18f385b2cf31fab046cd5a89732cf8bf288b148ba79cd67a8113",
       "some_data"=>17},
     "key"=>"K117"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "61ece2499ceeee31fb88b8c2ed8b882fa6f3b519215e6f8ade67224e93ec9129",
       "some_data"=>18},
     "key"=>"K118"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "97b74e89c5cfa3b52a87abd3ed596fbbfa7ac72ffe6e80ffdeb2ba2684a28eab",
       "some_data"=>19},
     "key"=>"K119"}]}]
["K116",
 {"cut_level"=>3,
  "uuid"=>"K116",
  "next_uuid"=>nil,
  "nodes"=>
   [{"forward"=>[1, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "afe33c9e81d85ea74d0682cd504c24cc858eaec63423c74553158d9cbe0aa51f",
       "some_data"=>16},
     "key"=>"K116"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "537eff6101dc18f385b2cf31fab046cd5a89732cf8bf288b148ba79cd67a8113",
       "some_data"=>17},
     "key"=>"K117"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "61ece2499ceeee31fb88b8c2ed8b882fa6f3b519215e6f8ade67224e93ec9129",
       "some_data"=>18},
     "key"=>"K118"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "97b74e89c5cfa3b52a87abd3ed596fbbfa7ac72ffe6e80ffdeb2ba2684a28eab",
       "some_data"=>19},
     "key"=>"K119"}]}]
true
------
["K109",
 {"cut_level"=>3,
  "uuid"=>"K109",
  "next_uuid"=>"K110",
  "nodes"=>
   [{"forward"=>[0, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "647cebde3cee15a14852c189b058c6ac95f1919d5303f8ce375b106aea011880",
       "some_data"=>9},
     "key"=>"K109"}]}]
["K109",
 {"cut_level"=>3,
  "uuid"=>"K109",
  "next_uuid"=>"K110",
  "nodes"=>
   [{"forward"=>[0, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "647cebde3cee15a14852c189b058c6ac95f1919d5303f8ce375b106aea011880",
       "some_data"=>9},
     "key"=>"K109"}]}]
true
------
["K110",
 {"cut_level"=>3,
  "uuid"=>"K110",
  "next_uuid"=>"K111",
  "nodes"=>
   [{"forward"=>[0, 0, 0],
     "value"=>
      {"__version__"=>
        "296b49a3fd57a8ae4ab33c8398afd7a2a03ff4b1b1e01108babba1b6004eb0d3",
       "some_data"=>10},
     "key"=>"K110"}]}]
["K110",
 {"cut_level"=>3,
  "uuid"=>"K110",
  "next_uuid"=>"K111",
  "nodes"=>
   [{"forward"=>[0, 0, 0],
     "value"=>
      {"__version__"=>
        "296b49a3fd57a8ae4ab33c8398afd7a2a03ff4b1b1e01108babba1b6004eb0d3",
       "some_data"=>10},
     "key"=>"K110"}]}]
true
------
["K111",
 {"cut_level"=>3,
  "uuid"=>"K111",
  "next_uuid"=>"K116",
  "nodes"=>
   [{"forward"=>[1, 0, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "0ea20a1dabbd150d04e36bb61993d0966c0dad8277d4926eb6afd89ffd2de330",
       "some_data"=>11},
     "key"=>"K111"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "dc20fc7bcfa399b07fff58ec5982a6f44c4b117812fca04473c4e4d8f4af0465",
       "some_data"=>12},
     "key"=>"K112"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "2c9119a288c69e440980dc6199d2b50307b7467331fac106f67c4493cbbd9bdd",
       "some_data"=>13},
     "key"=>"K113"},
    {"forward"=>[4],
     "value"=>
      {"__version__"=>
        "2dfd74845c714a32e876abe6185c5e60d847a9ec3782e9be4f2115bfdda99cee",
       "some_data"=>14},
     "key"=>"K114"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "2206ae874cd2d78391c63dfc8c6f5d5f3b87b1ebe30088426a36ae9dea88af01",
       "some_data"=>15},
     "key"=>"K115"}]}]
["K111",
 {"cut_level"=>3,
  "uuid"=>"K111",
  "next_uuid"=>"K116",
  "nodes"=>
   [{"forward"=>[1, 0, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "0ea20a1dabbd150d04e36bb61993d0966c0dad8277d4926eb6afd89ffd2de330",
       "some_data"=>11},
     "key"=>"K111"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "dc20fc7bcfa399b07fff58ec5982a6f44c4b117812fca04473c4e4d8f4af0465",
       "some_data"=>12},
     "key"=>"K112"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "2c9119a288c69e440980dc6199d2b50307b7467331fac106f67c4493cbbd9bdd",
       "some_data"=>13},
     "key"=>"K113"},
    {"forward"=>[4],
     "value"=>
      {"__version__"=>
        "2dfd74845c714a32e876abe6185c5e60d847a9ec3782e9be4f2115bfdda99cee",
       "some_data"=>14},
     "key"=>"K114"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "2206ae874cd2d78391c63dfc8c6f5d5f3b87b1ebe30088426a36ae9dea88af01",
       "some_data"=>15},
     "key"=>"K115"}]}]
true
------
["K100",
 {"cut_level"=>3,
  "uuid"=>"K100",
  "next_uuid"=>"K102",
  "nodes"=>
   [{"forward"=>[1],
     "value"=>
      {"__version__"=>
        "bd7a9a57131fad1bed9ea71383abf6daf13d4d693a560622504d2450b9c1331c",
       "some_data"=>0},
     "key"=>"K100"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "0568fd1163c0980c5b1d25790e27154e367bf4d351e2f1cc81cff7d5130078cf",
       "some_data"=>1},
     "key"=>"K101"}]}]
["K100",
 {"cut_level"=>3,
  "uuid"=>"K100",
  "next_uuid"=>"K102",
  "nodes"=>
   [{"forward"=>[1],
     "value"=>
      {"__version__"=>
        "bd7a9a57131fad1bed9ea71383abf6daf13d4d693a560622504d2450b9c1331c",
       "some_data"=>0},
     "key"=>"K100"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "0568fd1163c0980c5b1d25790e27154e367bf4d351e2f1cc81cff7d5130078cf",
       "some_data"=>1},
     "key"=>"K101"}]}]
true
------
~/Experiments/Ruby/strokedb/strokedb-ruby $ ruby test/chunk_serialize.rb 
["K113",
 {"cut_level"=>3,
  "uuid"=>"K113",
  "next_uuid"=>nil,
  "nodes"=>
   [{"forward"=>[1, 3, 0, 0],
     "value"=>
      {"__version__"=>
        "2c9119a288c69e440980dc6199d2b50307b7467331fac106f67c4493cbbd9bdd",
       "some_data"=>13},
     "key"=>"K113"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "2dfd74845c714a32e876abe6185c5e60d847a9ec3782e9be4f2115bfdda99cee",
       "some_data"=>14},
     "key"=>"K114"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "2206ae874cd2d78391c63dfc8c6f5d5f3b87b1ebe30088426a36ae9dea88af01",
       "some_data"=>15},
     "key"=>"K115"},
    {"forward"=>[4, 6],
     "value"=>
      {"__version__"=>
        "afe33c9e81d85ea74d0682cd504c24cc858eaec63423c74553158d9cbe0aa51f",
       "some_data"=>16},
     "key"=>"K116"},
    {"forward"=>[5],
     "value"=>
      {"__version__"=>
        "537eff6101dc18f385b2cf31fab046cd5a89732cf8bf288b148ba79cd67a8113",
       "some_data"=>17},
     "key"=>"K117"},
    {"forward"=>[6],
     "value"=>
      {"__version__"=>
        "61ece2499ceeee31fb88b8c2ed8b882fa6f3b519215e6f8ade67224e93ec9129",
       "some_data"=>18},
     "key"=>"K118"},
    {"forward"=>[0, 0],
     "value"=>
      {"__version__"=>
        "97b74e89c5cfa3b52a87abd3ed596fbbfa7ac72ffe6e80ffdeb2ba2684a28eab",
       "some_data"=>19},
     "key"=>"K119"}]}]
["K113",
 {"cut_level"=>3,
  "uuid"=>"K113",
  "next_uuid"=>nil,
  "nodes"=>
   [{"forward"=>[1, 0, 0, 0],
     "value"=>
      {"__version__"=>
        "2c9119a288c69e440980dc6199d2b50307b7467331fac106f67c4493cbbd9bdd",
       "some_data"=>13},
     "key"=>"K113"},
    {"forward"=>[2],
     "value"=>
      {"__version__"=>
        "2dfd74845c714a32e876abe6185c5e60d847a9ec3782e9be4f2115bfdda99cee",
       "some_data"=>14},
     "key"=>"K114"},
    {"forward"=>[3, 3],
     "value"=>
      {"__version__"=>
        "2206ae874cd2d78391c63dfc8c6f5d5f3b87b1ebe30088426a36ae9dea88af01",
       "some_data"=>15},
     "key"=>"K115"},
    {"forward"=>[4, 0],
     "value"=>
      {"__version__"=>
        "afe33c9e81d85ea74d0682cd504c24cc858eaec63423c74553158d9cbe0aa51f",
       "some_data"=>16},
     "key"=>"K116"},
    {"forward"=>[5],
     "value"=>
      {"__version__"=>
        "537eff6101dc18f385b2cf31fab046cd5a89732cf8bf288b148ba79cd67a8113",
       "some_data"=>17},
     "key"=>"K117"},
    {"forward"=>[6, 6],
     "value"=>
      {"__version__"=>
        "61ece2499ceeee31fb88b8c2ed8b882fa6f3b519215e6f8ade67224e93ec9129",
       "some_data"=>18},
     "key"=>"K118"},
    {"forward"=>[0, 0],
     "value"=>
      {"__version__"=>
        "97b74e89c5cfa3b52a87abd3ed596fbbfa7ac72ffe6e80ffdeb2ba2684a28eab",
       "some_data"=>19},
     "key"=>"K119"}]}]
false
------
["K100",
 {"cut_level"=>3,
  "uuid"=>"K100",
  "next_uuid"=>"K113",
  "nodes"=>
   [{"forward"=>[1],
     "value"=>
      {"__version__"=>
        "bd7a9a57131fad1bed9ea71383abf6daf13d4d693a560622504d2450b9c1331c",
       "some_data"=>0},
     "key"=>"K100"},
    {"forward"=>[2, 8],
     "value"=>
      {"__version__"=>
        "0568fd1163c0980c5b1d25790e27154e367bf4d351e2f1cc81cff7d5130078cf",
       "some_data"=>1},
     "key"=>"K101"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "6d1dc31dd3b26c15c96e15615e08b49814677a1b7701784e4236fc930ebe460e",
       "some_data"=>2},
     "key"=>"K102"},
    {"forward"=>[4],
     "value"=>
      {"__version__"=>
        "5899a8b229a25b01db929a25cdf7214edcde6507cc28dc7bccb53d422ec3d89f",
       "some_data"=>3},
     "key"=>"K103"},
    {"forward"=>[5],
     "value"=>
      {"__version__"=>
        "8526d1d9784d89a13e42289ef068ff8066966af0c7712a81a0b995cf6fd5564b",
       "some_data"=>4},
     "key"=>"K104"},
    {"forward"=>[6],
     "value"=>
      {"__version__"=>
        "59ffed01bea1ec0b6aa818eb5beb6d95fa58aa1cb8c3cf8740c5375faab6acf6",
       "some_data"=>5},
     "key"=>"K105"},
    {"forward"=>[7],
     "value"=>
      {"__version__"=>
        "e916f66fa5a0b0df29da7e1ef636a8ed60ce6fea96a5ec2f4e9560e21668c580",
       "some_data"=>6},
     "key"=>"K106"},
    {"forward"=>[8],
     "value"=>
      {"__version__"=>
        "cbbe0a809aa104784e691e6680c0df6f13c4e6171642daa96bb607aff627f7c2",
       "some_data"=>7},
     "key"=>"K107"},
    {"forward"=>[9, 0],
     "value"=>
      {"__version__"=>
        "e140c94e0b7f13926c37cc568072e159df028499c0f8ab6c3d792242a93a0600",
       "some_data"=>8},
     "key"=>"K108"},
    {"forward"=>[10],
     "value"=>
      {"__version__"=>
        "647cebde3cee15a14852c189b058c6ac95f1919d5303f8ce375b106aea011880",
       "some_data"=>9},
     "key"=>"K109"},
    {"forward"=>[11],
     "value"=>
      {"__version__"=>
        "296b49a3fd57a8ae4ab33c8398afd7a2a03ff4b1b1e01108babba1b6004eb0d3",
       "some_data"=>10},
     "key"=>"K110"},
    {"forward"=>[12],
     "value"=>
      {"__version__"=>
        "0ea20a1dabbd150d04e36bb61993d0966c0dad8277d4926eb6afd89ffd2de330",
       "some_data"=>11},
     "key"=>"K111"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "dc20fc7bcfa399b07fff58ec5982a6f44c4b117812fca04473c4e4d8f4af0465",
       "some_data"=>12},
     "key"=>"K112"}]}]
["K100",
 {"cut_level"=>3,
  "uuid"=>"K100",
  "next_uuid"=>"K113",
  "nodes"=>
   [{"forward"=>[1, 1],
     "value"=>
      {"__version__"=>
        "bd7a9a57131fad1bed9ea71383abf6daf13d4d693a560622504d2450b9c1331c",
       "some_data"=>0},
     "key"=>"K100"},
    {"forward"=>[2, 0],
     "value"=>
      {"__version__"=>
        "0568fd1163c0980c5b1d25790e27154e367bf4d351e2f1cc81cff7d5130078cf",
       "some_data"=>1},
     "key"=>"K101"},
    {"forward"=>[3],
     "value"=>
      {"__version__"=>
        "6d1dc31dd3b26c15c96e15615e08b49814677a1b7701784e4236fc930ebe460e",
       "some_data"=>2},
     "key"=>"K102"},
    {"forward"=>[4],
     "value"=>
      {"__version__"=>
        "5899a8b229a25b01db929a25cdf7214edcde6507cc28dc7bccb53d422ec3d89f",
       "some_data"=>3},
     "key"=>"K103"},
    {"forward"=>[5],
     "value"=>
      {"__version__"=>
        "8526d1d9784d89a13e42289ef068ff8066966af0c7712a81a0b995cf6fd5564b",
       "some_data"=>4},
     "key"=>"K104"},
    {"forward"=>[6],
     "value"=>
      {"__version__"=>
        "59ffed01bea1ec0b6aa818eb5beb6d95fa58aa1cb8c3cf8740c5375faab6acf6",
       "some_data"=>5},
     "key"=>"K105"},
    {"forward"=>[7],
     "value"=>
      {"__version__"=>
        "e916f66fa5a0b0df29da7e1ef636a8ed60ce6fea96a5ec2f4e9560e21668c580",
       "some_data"=>6},
     "key"=>"K106"},
    {"forward"=>[8, 8],
     "value"=>
      {"__version__"=>
        "cbbe0a809aa104784e691e6680c0df6f13c4e6171642daa96bb607aff627f7c2",
       "some_data"=>7},
     "key"=>"K107"},
    {"forward"=>[9, 0],
     "value"=>
      {"__version__"=>
        "e140c94e0b7f13926c37cc568072e159df028499c0f8ab6c3d792242a93a0600",
       "some_data"=>8},
     "key"=>"K108"},
    {"forward"=>[10],
     "value"=>
      {"__version__"=>
        "647cebde3cee15a14852c189b058c6ac95f1919d5303f8ce375b106aea011880",
       "some_data"=>9},
     "key"=>"K109"},
    {"forward"=>[11],
     "value"=>
      {"__version__"=>
        "296b49a3fd57a8ae4ab33c8398afd7a2a03ff4b1b1e01108babba1b6004eb0d3",
       "some_data"=>10},
     "key"=>"K110"},
    {"forward"=>[12],
     "value"=>
      {"__version__"=>
        "0ea20a1dabbd150d04e36bb61993d0966c0dad8277d4926eb6afd89ffd2de330",
       "some_data"=>11},
     "key"=>"K111"},
    {"forward"=>[0],
     "value"=>
      {"__version__"=>
        "dc20fc7bcfa399b07fff58ec5982a6f44c4b117812fca04473c4e4d8f4af0465",
       "some_data"=>12},
     "key"=>"K112"}]}]
false
------



=end

