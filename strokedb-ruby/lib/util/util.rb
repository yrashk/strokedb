require 'digest/sha2'
require 'uuidtools'

module StrokeDB
  module Util

    class ::Object
      # Uses references to documents (compared to to_raw using hashes instead)
      def to_optimized_raw
        case self
        when Array
          map{|v| v.to_optimized_raw }
        when Hash
          new_hash = {}
          each_pair{|k,v| new_hash[k.to_optimized_raw] = v.to_optimized_raw}
          new_hash
        else
          self
        end
      end
    end

    def self.sha(str)
      Digest::SHA256.hexdigest(str)
    end

    def self.random_uuid
      ::UUID.random_create.to_s
    end
    def self.random_uuid_raw
      ::UUID.random_create.raw
    end

    class CircularReferenceCondition < Exception ; end
    class << self
      def catch_circular_reference(value)
        stack = Thread.current['StrokeDB.reference_stack'] ||= []
        raise CircularReferenceCondition if stack.find{|v| value == v}
        stack << value
        yield
        stack.pop
      end
    end
  end
  
  class ::String
    # Assuming that string contains formatted UUID,
    # convert it to raw 16 bytes.
    def to_raw_uuid
      ::UUID.parse(self).raw
    end
    # Assuming that string contains raw UUID bytes,
    # convert to formatted string.
    def to_formatted_uuid
      ::UUID.parse_raw(self).to_s
    end
  end
end
