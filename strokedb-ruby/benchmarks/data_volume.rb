require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

@path = File.dirname(__FILE__) + "/../test/storages/data_volume"

SimpleSkiplist.optimize!(:C)

[true,false].each do |decompose|
  [2000].each do |n|

    record = "D"*512

    bm(60) do |x| 
      FileUtils.rm_rf @path
      data_volume = DataVolume.new(:path => @path, :decompose_compound_types => decompose)

      records = []
      n.times {|v| records << {"static" => "unique", "some_val_#{v}" => v,"some_val1_#{v}" => "_#{v}", "some_valX_#{v}" => "#{v}_"   } }

      offsets = []
      x.report("Inserting #{n} complex different records (decompose: #{decompose})") do
        records.each {|rec| offsets << data_volume.insert!(rec) }
      end

      x.report("Reading #{n} complex different records (decompose: #{decompose})") do
        offsets.each do |offset| 
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
      data_volume = DataVolume.new(:path => @path, :decompose_compound_types => decompose)

      records = []
      n.times {|v| records << {"static" => "unique" } }

      offsets = []
      x.report("Inserting #{n} complex static records (decompose: #{decompose})") do
        records.each {|rec| offsets << data_volume.insert!(rec)  }
      end

      x.report("Reading #{n} complex static records (decompose: #{decompose})") do
        offsets.each do |offset| 
          data_volume.read(offset)  
        end
      end

      data_volume.close!

    end

  end
end