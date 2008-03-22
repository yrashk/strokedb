module StrokeDB
  class DistributedPointer
    attr_accessor :volume_uuid, :offset
    # raw_uuid is a raw bytestring, not nicely formatted UUID! 
    def initialize(raw_uuid, offset)
      @volume_uuid = raw_uuid
      @offset      = offset
    end
    def self.unpack(string160bit)
      dp = new(nil, nil)
      dp.volume_uuid = string160bit[0, 16]
      dp.offset =  string160bit[16, 4].unpack("L")[0]
      dp
    end
    def pack
      @volume_uuid + [@offset].pack("L")
    end
  end
end
