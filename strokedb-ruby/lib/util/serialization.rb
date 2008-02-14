module StrokeDB
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
      Marshal.dump(x)
    end
    def deserialize(x)
     Marshal.load(x)
    end
  end

  
  def self.serialization_method=(method_name)
    StrokeDB.extend("::StrokeDB::#{method_name.to_s.camelize}SerializationMethod".constantize)
  end
  
  self.serialization_method = :json
  
  
end