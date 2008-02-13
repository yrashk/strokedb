module StrokeDB
  class LamportTimestamp
    MAX_COUNTER = 2**64
    BASE        = 16
    BASE_LENGTH = 16
    
    attr_reader :counter, :salt
    
    def initialize(c = 0, __salt = Util.random_uuid)
      if c > MAX_COUNTER
        raise CounterOverflow.new, "Max counter value is 2**64"
      end
      @counter = c
      @salt    = __salt 
    end
    def next
      LamportTimestamp.new(@counter + 1, @salt)
    end
    def next!
      @counter += 1
      self
    end
    def dup
      LamportTimestamp.new(@counter, @salt)
    end
    def marshal_dump
      @counter.to_s(BASE).rjust(BASE_LENGTH, '0') + @salt
    end 
    def marshal_load(dumped)
      @counter = dumped[0,           BASE_LENGTH].to_i(BASE)
      @salt    = dumped[BASE_LENGTH, 36]
      self
    end
    
    # Raw format
    def self.from_raw(raw_string)
      new.marshal_load(raw_string)
    end
    def to_raw
      marshal_dump
    end
    
    def to_s
      marshal_dump
    end
    def <=>(other)
      primary = (@counter <=> other.counter)
      primary == 0 ? (@salt <=> other.salt) : primary
    end
    def ==(other)
      @counter == other.counter && @salt == other.salt
    end
    def <(other)
      (self <=> other) < 0
    end
    def <=(other)
      (self <=> other) <= 0
    end
    def >(other)
      (self <=> other) > 0
    end
    def >=(other)
      (self <=> other) >= 0
    end
    def self.zero(__salt = Util.random_uuid)
      ts = new(0)
      ts.instance_variable_set(:@salt, __salt)
      ts
    end
    def self.zero_string
      "0"*BASE_LENGTH + NIL_UUID
    end
    class CounterOverflow < Exception; end
  end
end
