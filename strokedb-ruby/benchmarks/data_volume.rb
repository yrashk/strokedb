require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

@path = File.dirname(__FILE__) + "/../test/storages/data_volume"

SimpleSkiplist.optimize!(:C)

[2000].each do |n|

  record = "D"*512

  bm(60) do |x| 
    FileUtils.rm_rf @path
    data_volume = DataVolume.new(:path => @path)

    records = []
    n.times {|v| records << {"static" => "unique", "some_val_#{v}" => v } }
    
    offsets = []
    x.report("Inserting #{n} complex different records") do
      records.each {|rec| offsets << data_volume.insert!(rec) }
    end

    x.report("Reading #{n} complex different records") do
      offsets.each_with_index do |offset,n| 
        data_volume.read(offset)  
      end
    end
    
    data_volume.close!

  end

end

[2000].each do |n|

  record = "D"*512

  bm(60) do |x| 
    FileUtils.rm_rf @path
    data_volume = DataVolume.new(:path => @path)

    records = []
    n.times {|v| records << {"static" => "unique" } }
    
    offsets = []
    x.report("Inserting #{n} complex static records") do
      records.each {|rec| offsets << data_volume.insert!(rec) }
    end

    x.report("Reading #{n} complex static records") do
      offsets.each_with_index do |offset,n| 
        data_volume.read(offset)  
      end
    end
    
    data_volume.close!

  end

end