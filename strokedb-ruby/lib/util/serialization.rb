module StrokeDB

  class ::Array
    def to_raw
      map do |v|
        v.respond_to?(:to_raw) ? v.to_raw : v
      end
    end
  end
  
  module JsonSerializationMethod
    def serialize(x)
      x.to_json
    end
    def deserialize(x)
      ActiveSupport::JSON.decode(x)
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
    StrokeDB.extend("::StrokeDB::#{method_name.to_s.camelize}SerializationMethod".constantize)
  end
  
  self.serialization_method = :marshal
  
  
end