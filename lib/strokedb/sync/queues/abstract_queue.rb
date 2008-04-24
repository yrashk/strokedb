module StrokeDB
  class AbstractQueue
    attr_accessor :on_receive
    def initialize(*args)
      raise "Abstract queue cannot be instantiated!"
    end
    
    def push(object)
      raise "Abstract queue cannot accept objects"
    end
    alias :<< :push
    
    def on_recieve(&block)
      @on_receive = block || @on_receive
    end
    
    def pop
      raise "Abstract queue cannot return objects"
    end
    
    def size
      raise "Abstract queue doesn't have a size"
    end
    alias :length :size
  end
end
