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
    
    # on_receive callback is called when the queue decides do pop
    # out an object. If there is no on_receive, it waits for the #pop call.
    def on_receive(&block)
      self.on_receive = block if block
      @on_receive
    end
    
    def on_receive=(proc)
      @on_receive = proc
      # define notify! method to invoke a callback
      class << self
        def notify!
          while item = pop
            @on_receive.call(item)
          end
        end
      end
      proc
    end
    
    # Get an object out of the queue. 
    # nil is returned when nothing is to be returned.
    def pop
      raise "Abstract queue cannot return objects"
    end
    
    def size
      raise "Abstract queue doesn't have a size"
    end
    alias :length :size
  
  protected
  
    def notify!
      # do nothing while on_receive is not set
    end
  
  end
end
