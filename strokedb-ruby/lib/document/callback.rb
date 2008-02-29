module StrokeDB
  class Callback
    attr_reader :origin, :name
    def initialize(origin,name,&block)
      @origin, @name, @block = origin, name, block
    end
    def call(*args)
      @block.call(*args)
    end
  end
end