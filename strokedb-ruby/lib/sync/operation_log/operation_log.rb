module StrokeDB
  class OperationLog
    attr_accessor :storage, :timestamp
    def initialize(storage)
      @storage = storage
    end
    
    def insert(op)
      ts = @timestamp.next!
      op.timestamp = ts
      
    end
    
    def merge(ops)
      
    end
  end
end
