module StrokeDB

  class ::Array
    def to_raw
      map do |v|
        v.respond_to?(:to_raw) ? v.to_raw : v
      end
    end
  end

  class ::Hash
    def to_raw
      raw_hash = {}
      map do |k,v|
        _k = k.respond_to?(:to_raw) ? k.to_raw : k
        _v = v.respond_to?(:to_raw) ? v.to_raw : v
        raw_hash[_k] = _v
      end
      raw_hash
    end
  end
  
  module JsonSerializationMethod
    def serialize(x)
      x.to_json
    end
    def deserialize(x)
      JSON.parse(x)
    end
  end

  module MarshalSerializationMethod
    def serialize(x)
      x = x.to_raw if x.respond_to?(:to_raw)
      Marshal.dump(x)
    end
    def deserialize(x)
     Marshal.load(x)
    end
  end

  
  def self.serialization_method=(method_name)
    StrokeDB.extend StrokeDB.const_get("#{method_name.to_s.camelize}SerializationMethod")
  end
  
  self.serialization_method = :marshal
  
  
end
