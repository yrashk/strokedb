require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

@path = File.dirname(__FILE__) + "/../test/storages/map_volume"


[2**10,2**12,2**16].each do |n|

  [512,1024,4096].each do |s|
    record = "D"*s

    bm(60) do |x| 
      FileUtils.rm_rf @path
      map_volume = MapVolume.new(:path => @path, :record_size => s)

      x.report("Inserting #{n} records of #{s} bytes") do
        n.times { map_volume.insert!(record) }
      end

    end

  end
end