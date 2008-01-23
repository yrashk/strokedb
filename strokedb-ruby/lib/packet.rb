module StrokeDB
  class Packet
    def initialize(documents)
      @documents = documents
    end
    
    # Just an example, it is not worth using in a real world, probably
    def to_json
      @documents.collect{|doc| doc.to_json(:transmittal => true)}
    end
    
  end
end