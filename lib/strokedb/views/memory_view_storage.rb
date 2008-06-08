module StrokeDB
  class MemoryViewStorage < ViewStorage
    
    def initialize(options = {})
      @list = Skiplist.new
    end
    
    def clear!
      @list = Skiplist.new
    end
    
  end
end
