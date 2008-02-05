require 'digest/sha2'

module StrokeDB  
  module Util

    module ::Enumerable
      def map_with_index
        collected=[]
        each_with_index {|item, index| collected << yield(item, index) }
        collected
      end
      alias :collect_with_index :map_with_index
    end

    class HashWithSortedKeys < Hash
      def keys_with_sort
        keys_without_sort.sort
      end
      alias_method_chain :keys, :sort
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

  end
end