require 'thread'
module StrokeDB
  # Instant queue pops objects as soons, as they arrive
  # Queue may be configured to use any #push/#pop storage
  # but uses Array as a default.
  class InstantQueue < AbstractQueue
    
    def initialize(params)
      @storage = params[:storage]
      unless @storage
        @storage = Queue.new
        class << self
          def pop
            @storage.pop(true) # non-blocking Queue#pop
          end
        end
      end
    end
    
    def push(obj)
      @storage.push(obj)
      notify!
      self
    end
    
    def pop
      @storage.pop
    end
    
    def size
      @storage.size
    end
  end
end
