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

    unless RUBY_PLATFORM =~ /java/
      require 'uuidtools'
      def self.random_uuid
        ::UUID.random_create.to_s
      end
    end

    class CircularReferenceCondition < Exception ; end
    class << self
      def catch_circular_reference(value,name = 'StrokeDB.reference_stack')
        stack = Thread.current[name] ||= []
        raise CircularReferenceCondition if stack.find{|v| value == v}
        stack << value
        yield
        stack.pop
      end
    end
  end
end
