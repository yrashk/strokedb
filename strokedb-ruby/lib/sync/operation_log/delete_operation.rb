module StrokeDB
  class DeleteOperation < Operation
    attr_accessor :uuid
    def initialize(uuid)
      super
      @uuid = uuid
    end
    def to_raw
      super(@uuid)
    end
    def self.from_raw(store, raw_uuid)
      new(raw_uuid)
    end
  end
end
