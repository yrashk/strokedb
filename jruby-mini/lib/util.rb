require 'digest/sha1'

module StrokeDB  
  module Util
    class HashWithSortedKeys < Hash
      def keys_with_sort
        keys_without_sort.sort
      end
      alias_method_chain :keys, :sort
    end
    
    def self.sha(str)
      Digest::SHA2.hexdigest(str)
    end
    
    # Stupid implementation.
    # TODO: use gem install uuid (http://trac.labnotes.org/cgi-bin/trac.cgi/browser/uuid)
    # valid one: "550e8400-e29b-41d4-a716-446655440000"
    def self.random_uuid
      a = "1234567890abcdef"
      s = ''
      [8,4,4,4,12].map do |len| 
        (1..len).map{ a[rand(16),1] }.join
      end.join '-'
    end
    
  end
end