$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

@path = File.dirname(__FILE__) + "/../../spec/temp/storages/data_volume"

def benchmark!(lang)
  [1000].each do |n|
    bm(60) do |x| 
      FileUtils.rm_rf @path
      skiplist = SkiplistVolume.new(:path => @path, :max_log_size => 1024*4000)

      records = []
      n.times {|v| records << ["key#{v}".ljust(128," "),"val#{v}".ljust(128," ")] }

      offsets = []
      x.report("Inserting #{n} pairs [#{lang}]") do
        records.each {|rec| skiplist.insert(rec[0],rec[1]) }
      end

      x.report("Reading #{n} pairs [#{lang}]") do
        records.each {|rec| skiplist.find(rec[0]) }
      end
      
      x.report("Dumping #{n/100} items [#{lang}]") do
        (n/100).times {|i| skiplist.dump! }
      end
      
      skiplist.close!

    end
  end  
end

benchmark!("Ruby")

SimpleSkiplist.optimize!(:C)

benchmark!("C")

