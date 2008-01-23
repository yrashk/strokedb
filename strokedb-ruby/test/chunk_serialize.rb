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

fs = FileStore.new "some_path"

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
 pp [k, v.to_raw]
 #puts v.skiplist.to_s
}

#pp head_chunk.to_raw

=begin
 !!!!!gimme results!!!!:-O
 
 ~/Experiments/Ruby/strokedb/strokedb-ruby $ ruby test/chunk_serialize.rb 
["K112",
 {:nodes=>
   [{:key=>"K112",
     :value=>
      "{\"__version__\": \"dc20fc7bcfa399b07fff58ec5982a6f44c4b117812fca04473c4e4d8f4af0465\", \"some_data\": 12}",
     :forward=>[1, 7, 0]},
    {:key=>"K113",
     :value=>
      "{\"__version__\": \"2c9119a288c69e440980dc6199d2b50307b7467331fac106f67c4493cbbd9bdd\", \"some_data\": 13}",
     :forward=>[2]},
    {:key=>"K114",
     :value=>
      "{\"__version__\": \"2dfd74845c714a32e876abe6185c5e60d847a9ec3782e9be4f2115bfdda99cee\", \"some_data\": 14}",
     :forward=>[3]},
    {:key=>"K115",
     :value=>
      "{\"__version__\": \"2206ae874cd2d78391c63dfc8c6f5d5f3b87b1ebe30088426a36ae9dea88af01\", \"some_data\": 15}",
     :forward=>[4]},
    {:key=>"K116",
     :value=>
      "{\"__version__\": \"afe33c9e81d85ea74d0682cd504c24cc858eaec63423c74553158d9cbe0aa51f\", \"some_data\": 16}",
     :forward=>[5]},
    {:key=>"K117",
     :value=>
      "{\"__version__\": \"537eff6101dc18f385b2cf31fab046cd5a89732cf8bf288b148ba79cd67a8113\", \"some_data\": 17}",
     :forward=>[6]},
    {:key=>"K118",
     :value=>
      "{\"__version__\": \"61ece2499ceeee31fb88b8c2ed8b882fa6f3b519215e6f8ade67224e93ec9129\", \"some_data\": 18}",
     :forward=>[7]},
    {:key=>"K119",
     :value=>
      "{\"__version__\": \"97b74e89c5cfa3b52a87abd3ed596fbbfa7ac72ffe6e80ffdeb2ba2684a28eab\", \"some_data\": 19}",
     :forward=>[0, 0]}],
  :uuid=>"K112",
  :cut_level=>3,
  :next_uuid=>nil}]
["K110",
 {:nodes=>
   [{:key=>"K110",
     :value=>
      "{\"__version__\": \"296b49a3fd57a8ae4ab33c8398afd7a2a03ff4b1b1e01108babba1b6004eb0d3\", \"some_data\": 10}",
     :forward=>[1, 0, 0]},
    {:key=>"K111",
     :value=>
      "{\"__version__\": \"0ea20a1dabbd150d04e36bb61993d0966c0dad8277d4926eb6afd89ffd2de330\", \"some_data\": 11}",
     :forward=>[0]}],
  :uuid=>"K110",
  :cut_level=>3,
  :next_uuid=>"K112"}]
["K100",
 {:nodes=>
   [{:key=>"K100",
     :value=>
      "{\"__version__\": \"bd7a9a57131fad1bed9ea71383abf6daf13d4d693a560622504d2450b9c1331c\", \"some_data\": 0}",
     :forward=>[1]},
    {:key=>"K101",
     :value=>
      "{\"__version__\": \"0568fd1163c0980c5b1d25790e27154e367bf4d351e2f1cc81cff7d5130078cf\", \"some_data\": 1}",
     :forward=>[2]},
    {:key=>"K102",
     :value=>
      "{\"__version__\": \"6d1dc31dd3b26c15c96e15615e08b49814677a1b7701784e4236fc930ebe460e\", \"some_data\": 2}",
     :forward=>[3]},
    {:key=>"K103",
     :value=>
      "{\"__version__\": \"5899a8b229a25b01db929a25cdf7214edcde6507cc28dc7bccb53d422ec3d89f\", \"some_data\": 3}",
     :forward=>[4]},
    {:key=>"K104",
     :value=>
      "{\"__version__\": \"8526d1d9784d89a13e42289ef068ff8066966af0c7712a81a0b995cf6fd5564b\", \"some_data\": 4}",
     :forward=>[5, 0]},
    {:key=>"K105",
     :value=>
      "{\"__version__\": \"59ffed01bea1ec0b6aa818eb5beb6d95fa58aa1cb8c3cf8740c5375faab6acf6\", \"some_data\": 5}",
     :forward=>[6]},
    {:key=>"K106",
     :value=>
      "{\"__version__\": \"e916f66fa5a0b0df29da7e1ef636a8ed60ce6fea96a5ec2f4e9560e21668c580\", \"some_data\": 6}",
     :forward=>[7]},
    {:key=>"K107",
     :value=>
      "{\"__version__\": \"cbbe0a809aa104784e691e6680c0df6f13c4e6171642daa96bb607aff627f7c2\", \"some_data\": 7}",
     :forward=>[8]},
    {:key=>"K108",
     :value=>
      "{\"__version__\": \"e140c94e0b7f13926c37cc568072e159df028499c0f8ab6c3d792242a93a0600\", \"some_data\": 8}",
     :forward=>[9]},
    {:key=>"K109",
     :value=>
      "{\"__version__\": \"647cebde3cee15a14852c189b058c6ac95f1919d5303f8ce375b106aea011880\", \"some_data\": 9}",
     :forward=>[0]}],
  :uuid=>"K100",
  :cut_level=>3,
  :next_uuid=>"K110"}]

  
   
=end