module StrokeDB
  
  #  k-dimensional skiplist, version 2 
  # (according to Bradford G. Nickerson,
  #  Skip List Data Structures for Multidimensional Data)
  class KDSkiplist2
    
    # Initialize with a set of dimensions 
    #
    # Examples:
    #   KDSkiplist.new([:x,    :y])
    #   KDSkiplist.new(['name', 'age', 'gender'])
    #
    def initialize(dimensions)
      @dimensions = dimensions
    end
    
    # Inserts some object to a k-d list.
    # Relies on a #[] method to access dimensions slots.
    def insert(slots, __cheater_levels = nil)
      
    end
    
    # Find a subset of data in a multidimensional range.
    # If range is not given for some dimension, it is 
    # assumed to be (-∞; +∞)
    # Semi-infinite range can be applied in such way:
    #
    #   :slot => [nil, 42]  # => (-∞; 42]
    #   :slot => [42, nil]  # => [42; +∞)
    #
    # Thus, nil is not a valid value for a slot. 
    # Slot with a nil value is considered missing.
    # 
    # Examples:
    #  list.find(:x => 10..20,   :y => 30..70)    # 
    #  list.find(:x => [10, 20], :y => [30, nil]) # :y is within [30; +∞)
    #  list.find(:x => [10, 20])                  # :y is within (-∞; +∞)
    #
    # Returns an Array instance (empty when nothing found).
    # 
    def find(ranges)
      
    end
    
      
  end
  
  
  #  k-dimensional skiplist, version 3
  class KDSkiplist3
    
  end
  
end
