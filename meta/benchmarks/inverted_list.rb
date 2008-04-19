$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark 

N_INSERTS       = (ENV['N_INSERTS'] || 10000 ).to_i
N_FINDS         = 10000
N_SLOTS         = 5
TOTAL_SLOTS     = 10
SLOT_NAME_SIZE  = (ENV['SLOT_NAME_SIZE'] || 5).to_i
SLOT_VALUE_SIZE = (ENV['SLOT_VALUE_SIZE'] || 5).to_i

def generate_names(n, name_size)
  a = (name_size*0.7).ceil
  b = (name_size*1.5).floor
  Symbol.all_symbols.select{|s| s=s.to_s; (s =~ /^[a-zA-Z_]{#{a},#{b}}$/)}.map{|e| e.to_s}.sort{rand-0.5}[0,n]
end

def insert_random_doc(list, nslots)
  s = {}
  (1 + nslots/2 + rand(nslots)).times {
    s[SLOTS_NAMES[rand(SLOTS_NAMES.size)]] = rand(2**(SLOT_VALUE_SIZE - 1 + rand(3))).to_s(2)
  }
  list.insert(s, rand(2**64).to_s(36))
end

SLOTS_NAMES  = generate_names(TOTAL_SLOTS, SLOT_NAME_SIZE)

list = InvertedList.new

#require 'ruby-prof'

# Profile the code
#RubyProf.start

bm(48) do |x| 
  x.report("Building index (#{N_INSERTS} docs)") do
    buf = []
    N_INSERTS.times do
      insert_random_doc(list, N_SLOTS)
    end
  end
  x.report("Reading index (1 attribute, #{N_FINDS} queries)") do
    N_FINDS.times do |i|
      list.find(SLOTS_NAMES[i % SLOTS_NAMES.size] => rand(2**(SLOT_VALUE_SIZE - 1 + rand(3))).to_s(2))
    end
  end
end

#result = RubyProf.stop
#printer = RubyProf::GraphHtmlPrinter.new(result)
#printer.print(STDOUT, 0)


