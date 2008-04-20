$:.unshift File.dirname(__FILE__) + "/../../lib"
require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

@path = File.dirname(__FILE__) + "/../../spec/temp/storages/archive_volume"

SimpleSkiplist.optimize!(:C)

  [2000].each do |n|

    record = "D"*512

    bm(60) do |x| 
      FileUtils.rm_rf @path
      archive = ArchiveVolume.new(:raw_uuid => Util.random_uuid_raw, :path => @path)

      records = []
      n.times {|v| records << {"static" => "unique", "some_val_#{v}" => v,"some_val1_#{v}" => "_#{v}", "some_valX_#{v}" => "#{v}_"   }.to_json }

      offsets = []
      x.report("Inserting #{n} complex different records") do
        records.each {|rec| offsets << archive.insert(rec) }
      end

      x.report("Reading #{n} complex different records") do
        offsets.each do |offset| 
          archive.read(offset)  
        end
      end

      archive.close!

    end

  end

  [2000].each do |n|

    record = "D"*512

    bm(60) do |x| 
      FileUtils.rm_rf @path
      archive = ArchiveVolume.new(:raw_uuid => Util.random_uuid_raw, :path => @path)

      records = []
      n.times {|v| records << {"static" => "unique" }.to_json }

      offsets = []
      x.report("Inserting #{n} complex static records") do
        records.each {|rec| offsets << archive.insert(rec)  }
      end

      x.report("Reading #{n} complex static records") do
        offsets.each do |offset| 
          archive.read(offset)  
        end
      end

      archive.close!

    end

  end
