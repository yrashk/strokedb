require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark


@path = File.dirname(__FILE__) + "/../test/storages/map_volume"
FileUtils.rm_rf @path


[2**10].each do |n|

  record = "D"*512

  bm(50) do |x| 
    map_volume = MapVolume.new(:path => @path, :capacity => n, :record_size => 512)

    x.report("Inserting #{n} records of 512 bytes") do
      n.times { map_volume.insert!(record) }
    end

  end

end