module StrokeDB
  class Store
    def new_doc(slots={})
      Document.new(self,slots)
    end

    def new_replica(slots={})
      Replica.new(self,slots)
    end

  protected

    def load_doc(uuid,json)
      returning doc = Document.new(self,ActiveSupport::JSON.decode(json)) do
        doc.instance_variable_set(:@uuid, uuid.is_a?(String) ? java.util.UUID.from_string(uuid) : uuid)
      end
    end
  end
end