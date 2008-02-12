module StrokeDB
  class PatchOperation < Operation
    attr_accessor :base_uuid, :base_timestamp, :diff_uuid, :diff
    def initialize(base_uuid, base_timestamp, diff)
      super
      @base_uuid      = base_uuid
      @base_timestamp = base_timestamp
      @diff_uuid      = diff.uuid
      @diff           = diff
    end
    def to_raw
      super([ @base_uuid, @base_timestamp.to_raw, @diff_uuid, @diff.to_raw ])
    end
    def self.from_raw(store, raw_content)
      new(raw_content[0], 
          LamportTimestamp.from_raw(raw_content[1]), 
          Document.from_raw(store, raw_content[2], raw_content[3]))
    end
  end
end
