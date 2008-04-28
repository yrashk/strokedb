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
      # "D<sign><number length (8 hex bytes)><hex>"
      def default_key_encode
        hex = self.abs.to_s(16)
        if self >= 0
          "D1" + [ hex.size ].pack("N").unpack("H*")[0] + hex
        else
          s = hex.size
          "D0" + [ 2**32 - s ].pack("N").unpack("H*")[0] + (16**s + self).to_s(16)
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
      STROKEDB_SPACE_CHAR = " ".freeze
      STROKEDB_KEY_CHAR   = "S".freeze
      def default_key_encode
        if self[STROKEDB_SPACE_CHAR]
          split(STROKEDB_SPACE_CHAR).default_key_encode
        else
          STROKEDB_KEY_CHAR + self
        end
      end
    end
    class ::Symbol
      def default_key_encode
        to_s.default_key_encode
      end
    end
    class ::Array
      def default_key_encode
        flatten.map{|e| e.default_key_encode }.join(" ")
      end
    end
    class ::Hash
      # Keys order is undefined, so just don't use this method.
      def default_key_encode
        raise(StandardError, "Hash cannot be used as a key! Please set up custom " +
                             "#encode_key method if you really need to.")
      end
    end
    class ::Time
      # Index key is in UTC format to provide correct sorting, but lacks timezone info.
      # slot.rb maintains timezone offset and keeps timezone-local time value
      STROKEDB_KEY_CHAR = "T".freeze
      def default_key_encode
        STROKEDB_KEY_CHAR + getgm.xmlschema(7)
      end
    end
  end
  
  class Document
    AT_SIGN = "@".freeze
    def default_key_encode
      AT_SIGN + uuid
    end
  end
  
  module DefaultKeyEncoder
    
    # nil       -> "A"  
    # false     -> "B"
    # true      -> "C"
    # Number    -> "D<sign><number bitlength (8 hex bytes)><integer>[.<decimal>]"
    # String    -> "S<string>"
    # Time      -> "T<xmlschema>"
    # Array     -> "<elem1 elem2 ...>"
    # Document  -> "@<UUID>"
    # 
    def self.encode(json)
      json.default_key_encode
    end
    
    A = "A".freeze
    B = "B".freeze
    C = "C".freeze
    D = "D".freeze
    S = "S".freeze
    T = "T".freeze
    X = "@".freeze
    S_= " ".freeze
    R = (1..-1).freeze
    
    def self.decode(string)
      values = string.split(S_).map do |token|
        pfx = token[0,1]
        case pfx
        when A
          nil
        when B
          false
        when C
          true
        when D
          int, rat = token[10, 666].split(".")
          sign = token[1, 1] == "1" ? 1 : -1
          size = token[2, 8].to_i(16)
          int = int.to_i(16)
          if sign == -1
            size = 2**32 - size
            int  = 16**size - int
          end
          rat ? sign*int + ("0."+rat).to_f : sign*int
        when S
          token[R]
        when X
          token[R]
        when T
          Time.xmlschema(token[R]).localtime
        else
          token  # unknown stuff is decoded as a string
        end
      end
      values.size > 1 ? values : values[0]
    end
  end
end
