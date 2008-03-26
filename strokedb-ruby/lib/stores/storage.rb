module StrokeDB
  class Storage
    include ChainableStorage

    attr_accessor :authoritative_source

    def initialize(opts={})
    end

  end
end
