require 'java'
# Some java overrides
module StrokeDB
  module Util
    def self.random_uuid
      java.util.UUID.random_uuid.to_s
    end
  end
end