require 'java'
# Some java overrides
module StrokeDB
  module Util
    def self.random_uuid
      java.util.UUID.random_uuid.to_s
    end
    def self.random_uuid_raw
      uuid = java.util.UUID.random_uuid
      [uuid.most_significant_bits, uuid.least_significant_bits].pack("Q2")
    end
  end
end
