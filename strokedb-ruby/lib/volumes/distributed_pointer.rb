module StrokeDB
  # DP is for pointing to DataVolume item. It can address zillions
  # of DataVolumes, 4 GB each.
  #
  # DP is stored as a 160 bit bytestring. First 128 bits is a volume UUID.
  # Next 32 bits is an offset in a volume (unsigned long). Hence, the limit
  # for DataVolume size: max 4 Gb. Actually, real-world applications would 
  # have relatively small datavolumes (about 64 Mb).
  class DistributedPointer
    attr_accessor :volume_uuid, :offset
    
    # Initialize pointer with given components.
    # * raw_uuid is a raw bytestring, not nicely formatted UUID! 
    # * offset is a positive integer
    #
    def initialize(raw_uuid, offset)
      @volume_uuid = raw_uuid
      @offset      = offset
    end
    
    # Creates a pointer object using binary string.
    #
    def self.unpack(string160bit)
      dp = new(nil, nil)
      dp.volume_uuid = string160bit[0, 16]
      dp.offset =  string160bit[16, 4].unpack("L")[0]
      dp
    end
    
    # Converts pointer object to it's string representation.
    #
    def pack
      @volume_uuid + [@offset].pack("L")
    end
    
    def inspect #:nodoc:
      "#<DistributedPointer #{@volume_uuid.to_formatted_uuid}:#{@offset}>"
    end
    
    alias :to_s :inspect
  end
end
