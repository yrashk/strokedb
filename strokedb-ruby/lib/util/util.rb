require 'digest/sha2'

module StrokeDB
  module Util
    module ::Enumerable
      # Map and each_with_index combined.
      # TODO: think about moving it to ActiveSupport
      def map_with_index
        collected=[]
        each_with_index {|item, index| collected << yield(item, index) }
        collected
      end
      alias :collect_with_index :map_with_index
    end

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

    unless RUBY_PLATFORM =~ /java/
      require 'uuidtools'
      def self.random_uuid
        ::UUID.random_create.to_s
      end
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
end
