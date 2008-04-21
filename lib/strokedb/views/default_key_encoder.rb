module StrokeDB
  module CoreExtensions
    class ::NilClass
      def default_key_encode; "A"; end
    end
    class ::FalseClass
      def default_key_encode; "B"; end
    end
    class ::TrueClass
      def default_key_encode; "C"; end
    end
    class ::Integer
      # This helps with natural sort order
      # "D<sign><number length (4 bytes)><hex>"
      def default_key_encode
        hex = self.abs.to_s(16)
        if self >= 0
          "D1" + [ hex.size ].pack("N") + hex
        else
          s = hex.size
          "D0" + [ 2**32 - s ].pack("N") + (16**s + self).to_s(16)
        end
      end
    end
    class ::Float
      # Encodes integer part and appends ratio part
      # "D<sign><number length (4 bytes)><hex>.<dec>"
      def default_key_encode
        i = self.floor
        r = self - i
        i.default_key_encode + r.to_s[1, 666]
      end
    end
    class ::String
      def default_key_encode
        "E" + self
      end
    end
    class ::Symbol
      def default_key_encode
        "E" + self.to_s
      end
    end
    class ::Array
      def default_key_encode
        "F" + map{|e| e.default_key_encode }.join("\x00")
      end
    end
    class ::Hash
      # Keys order is undefined, so just don't use this method.
      def default_key_encode
        "G" + map{|kv| kv.default_key_encode }.join("\x01")
      end
    end
  end
  
  class Document
    def default_key_encode
      __reference__
    end
  end
  
  module DefaultKeyEncoder
    
    # nil       -> "A"  
    # false     -> "B"
    # true      -> "C"
    # Number    -> "D<sign><number bitlength (4 bytes)><integer>[.<decimal>]"
    # String    -> "E<string>"
    # Array     -> "F<array.inspect>"
    # Hash      -> "G<hash.inspect>"
    # Document  -> "@<UUID.VERSION>"
    # 
    def self.encode(json)
      json.default_key_encode
    end
    
    A = "A".freeze
    B = "B".freeze
    C = "C".freeze
    D = "D".freeze
    E = "E".freeze
    F = "F".freeze
    G = "G".freeze
    X = "@".freeze
    
    def self.decode(string)
      case string[0,1]
      when A
        nil
      when B
        false
      when C
        true
      when D
        int, rat = string[6, 666].split(".")
        sign = string[1, 1] == "1" ? 1 : -1
        size = string[2, 4].unpack("N").first
        int = int.to_i(16)
        if sign == -1
          size = 2**32 - size
          int  = 16**size - int
        end
        rat ? sign*int + ("0."+rat).to_f : sign*int
      when E
        string[1..-1]
      when F
        raise "Arrays decoding is not supported!"
      when G
        raise "Hashes decoding is not supported!"
      when X
        raise "Document dereferencing in key decode is not supported!"
      end
    end
  end
end
