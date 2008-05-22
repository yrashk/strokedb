module StrokeDB
  class MemoryViewStorage < ViewStorage
    
    def initialize(options = {})
      @list = SimpleSkiplist.new
    end
    
    def clear!
      @list = SimpleSkiplist.new
    end
    
  end
end
