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

require 'util/blankslate'
require 'util/class_optimization'
require 'util/inflect'
require 'util/lazy_array'
require 'util/lazy_mapping_array'
require 'util/lazy_mapping_hash'
require 'util/serialization'
require 'util/uuid'
require 'util/xml'
require 'util/attach_dsl'
require 'time'
require 'util/java_util' if RUBY_PLATFORM =~ /java/