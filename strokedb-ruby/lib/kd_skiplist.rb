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
      @lists = @dimensions.map{ Skiplist.new() }
    end
    
    # Inserts some object to a k-d list.
    # Relies on a #[] method to access dimensions slots.
    def insert(object, __cheater_levels = nil)
      locations = []
      k = @dimensions.size
      
      # Allocation nodes per each dimension
      @dimensions.each_with_index do |d, i|
        node = Node.new(object[d], object)
        locations[i] = node
        @lists[i].insert(node.key, node, __cheater_levels ? __cheater_levels[d] : nil)
      end
      
      # Add references to all nodes to their copies in other dimensions
      @dimensions.each_with_index do |d, i1|
        0.upto(k - 2) do |j|
          i2 = (i1 + j + 1) % k
          locations[i1].pointers[i2] = locations[i2]
        end
      end
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
      results = []
      @dimensions.each_with_index do |d, i1|
        
      end
      
      # To perform a range search, we start with sets L and H of size k defining the lower and 
      # upper bounds of the search in each dimension.  We then use the following algorithm. 
      # k-d_Range_Search_v2(G,L,H,A) 
      # 1   A := empty set; 
      # 2   for i := 1 to k do 
      # 3     determine location bi of the smallest key in Si # Li; 
      # 4   d := 1; 
      # 5   repeat 
      # 6     if In_Range(bd, d, k, L, H, G) then 
      # 7       begin 
      # 8         add point at location bd to A; 
      # 9         bd := next location in Sd 
      # 10      end 
      # 11  until Kd > Hd; 
      #
      # In_Range(var b, var d, k, L, H, G) : boolean; 
      # {Determine if a point in a k-d skip list is completely inside a k-d range} 
      # 1   startd := d; startb := b; 
      # 2   repeat 
      # 3     begin 
      # 4       Kd := key at location b; 
      # 5         if Kd < Ld or Kd > Hd then 
      # 6           begin 
      # 7             In_Range := false; 
      # 8             b := next location in Sstartd after startb;              
      # 9             return; 
      # 10          end 
      # 11        d := mod(d,k) + 1; 
      # 12        b := b’s dimension pointer to dimension d; 
      # 13    end 
      # 14  until d = startd; 
      # 15  In_Range := true; 
      # 
    end
    
    def to_s
      "#<#{self.class.name} " +
      "@dimensions=#{@dimensions} " +
      "@lists=[#{@lists.join(", ")}]>"
    end
    
    
    # Utility classes
    
    class Node
      attr_accessor :key, :data, :pointers
      def initialize(key, data)
        @key      = key
        @data     = data
        @pointers = []
      end
      
      # Very special comparison operators.
      # nil is considered a signed infinity.
      # ( node < LowerBound )
      # ( node > HigherBound )
      # Compare with lower bound. value = nil is -infinity.
      def <(value)
        return false if value.nil?
        key < value
      end
      # Compare with higher bound. value = nil is +infinity.
      def >(value)
        return false if value.nil?
        key > value
      end
      
      def to_s
        "#<KDNode:#{@data.inspect}>"
      end
    end
      
  end
  
  
  #  k-dimensional skiplist, version 3
  class KDSkiplist3
    
  end
  
end
