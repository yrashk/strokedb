module StrokeDB
  class Callback
    attr_reader :origin, :name, :uid
    def initialize(origin, name, uid=nil, &block)
      @origin, @name, @uid, @block = origin, name, uid, block
    end
    def call(*args)
      @block.call(*args)
    end
  end
end