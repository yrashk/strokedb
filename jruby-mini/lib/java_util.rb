require 'java'

# Some java overrides
module StrokeDB
  module Util
    def self.sha(str)
      md = java.security.MessageDigest.get_instance("SHA-256")
      md.update str.to_java_bytes
      md.digest.to_a.collect{|i| java.lang.Integer.to_hex_string(i & 0xff) }.join
    end
    
    def self.random_uuid
      java.util.UUID.randomUUID
    end
  end
end