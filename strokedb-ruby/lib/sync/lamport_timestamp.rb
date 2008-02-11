module StrokeDB
  class LamportTimestamp
    MAX_COUNTER = 2**64
    BASE        = 16
    BASE_LENGTH = 16
    
    attr_reader :counter, :salt
    
    def initialize(c = 0)
      if c > MAX_COUNTER
        raise CounterOverflow.new, "Max counter value is 2**64"
      end
      @counter = c
      @salt    = generate_salt
    end
    def next
      LamportTimestamp.new(@counter + 1)
    end
    def marshal_dump
      @counter.to_s(BASE).rjust(BASE_LENGTH, '0') + @salt.to_s(BASE).rjust(BASE_LENGTH, '0')
    end 
    def marshal_load(dumped)
      @counter = dumped[0,           BASE_LENGTH].to_i(BASE)
      @salt    = dumped[BASE_LENGTH, BASE_LENGTH].to_i(BASE)
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
    class CounterOverflow < Exception; end
  private
    def generate_salt
      rand(2**64)
    end
  end
end
