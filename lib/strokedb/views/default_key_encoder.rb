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
        "D" + (self > 0 ? "1" : "0") + [hex.size].pack("N") + hex
      end
    end
    class ::Float
      # Encodes integer part and appends ratio part
      # "D<sign><number length (4 bytes)><hex>.<dec>"
      def default_key_encode
        i = self.to_i
        i.default_key_encode + (self - i).to_s[1, 666]
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
        "F" + map{|e| e.default_key_encode }.inspect
      end
    end
    class ::Hash
      # Keys order is undefined, so just don't use this method.
      def default_key_encode
        "G" + map{|k, v| [k.default_key_encode, v.default_key_encode] }.inspect
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
      prefix = string[0]
    
      case prefix
      when A
        nil
      when B
        false
      when C
        true
      when D
        int, rat = string[6, 666].split(".")
        rat ? int.to_i(16) + rat.to_f : int.to_i(16)
      when F
        
      when G
        
      when X
          
      end
    end
  end
end
