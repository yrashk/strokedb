require File.expand_path(File.dirname(__FILE__) + '/../util/class_optimization')
module StrokeDB
  # ChunkedSkiplist (CS) implements a distributed, concurrently accessible 
  # skiplist using SimpleSkiplist (SL) as building blocks.
  # Each instance contains a single instance of SimpleSkiplist.
  # Higher-level CS store references to lower-level SL as SL "data".
  # Lowest-level CS contains actual data.
  #
  # Regular state of the chunks (square brackets denote references): 
  #
  #                   ______        ___________________      
  #                 /        \    /                     \
  #    HEAD -> C1[ C2, C3 ], C2[ C4, C5 ], C3[ C6, C7 ], C4[data], ...
  # =>                  \__________________/
  #
  # Initial state is a single lowest-level chunk:
  # 
  #    HEAD -> C1[data]
  # 
  # When higher-level node is inserted, new skiplist is created.
  # Old skiplist is moved to a new chunk, current chunk uppers its level.
  #
  # ASYNCHRONOUS CONCURRENT INSERT
  #
  # SKiplists, by their nature, allow you to concurrently insert and
  # delete nodes. However, very little number of nodes must be locked
  # during update. In our implementation, we lock a whole chunk if it is
  # modified. Higher-level chunks are modified rarely, so they are not 
  # locked most of the time. Different chunks could be updated concurrently.
  # Read-only concurrent access is always possible no matter what nodes are  
  # locked for modification.
  #
  # ChunkedSkiplist has an API for asynchronous data access useful for
  # cöoperative multitasking, but it is also thread-safe for preemtive
  # multitasking, which is kinda nice feature, but is not to be evaluated
  # in a real-world applications.
  #
  # Chunked #find
  # 
  # Find may return an actual data or a reference to lower-level chunk.
  # It is a networking wrapper business to do interpret the result of #find.
  #
  # Insert is harder =) When new node level is higher than data chunk level
  # we have to insert into proxy chunk and create all the levels of proxy 
  # chunks down to the data chunk. If node level is low, we just insert 
  # node into appropriate data chunk.
  # The hard part about it are locking issues during insertion.
  #
  #
  class ChunkedSkiplist
    attr_accessor :lo_level, :hi_level, :probability, :container
    
    DEFAULT_MAXLEVEL     = 7
    DEFAULT_PROBABILITY  = 1/Math::E
    
    def initialize(lo_level = nil, hi_level = nil, probability = nil, container = nil)
      @lo_level = lo_level || 0
      @hi_level = hi_level || DEFAULT_MAXLEVEL
      @probability = probability || DEFAULT_PROBABILITY
      @container = container || SimpleSkiplist.new(nil, 
                             :maxlevel => @hi_level + 1, :probability => @probability)
    end
    
    # If chunk is not a lowest-level list, then it
    # contains references to other chunks. Hence, it is a "proxy".
    #
    def proxy?
      @lo_level > 0
    end
    
    # Insertion cases:
    # 
    #                               |
    #  [ levels 16..23 ]         |  |
    #  [ levels 08..15 ]      |  |  |
    #  [ levels 00..07 ]   |  |  |  | 
    #                      A  B  C  D
    #
    #  A - insert in a lower-level chunk
    #  B - insert in a 08..15-levels chunk, create new 0..7-level chunk
    #  C - insert in a 16..23-levels chunk, create new chunks of levels 
    #      0..7 and 8..15.
    #  D - create new 24..31-levels chunk with reference to previous head.
    #
    def insert(key, value, __level = nil)
      @container.insert(key, value, __level)
    end
    
    # Create new chunk, move local skiplist there,
    # create new skiplist here and insert 
    def promote_level(key, level, size)
      
    end
    
    def generate_chain(key, value, size, start_level)
      
    end
    
    # Finds reference to another chunk (if proxy) or an actual data.
    #
    def find(key)
      proxy? ? @container.find_nearest(key) : @container.find(key)
    end
    
    # Generates random level of arbitrary size.
    # In other words, it actually contains an infinite loop.
    def random_level
  	  p = @probability
  		l = 1
  		l += 1 while rand < p
  		return l
  	end
  end
end

if __FILE__ == $0
  require File.expand_path(File.dirname(__FILE__) + '/../data_structures/simple_skiplist.rb')
  require 'benchmark'
  
  
  
  
end
