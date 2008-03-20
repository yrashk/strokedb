require 'strokedb'
include StrokeDB

require 'benchmark'
include Benchmark

@path = File.dirname(__FILE__) + "/../test/storages/map_volume"


[2**12].each do |n|

  [MapVolume,MmapMapVolume].each do |klass|
    record = "D"*512

    bm(60) do |x| 
      FileUtils.rm_rf @path
      map_volume = klass.new(:path => @path, :capacity => n, :record_size => 512)

      x.report("Inserting #{n} records of 512 bytes [#{klass.name.demodulize}]") do
        n.times { map_volume.insert!(record) }
      end

    end

  end
end