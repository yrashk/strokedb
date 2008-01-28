module StrokeDB
  # BrickNetwork is a network of connected points in a k-dimensional space,
  # 
  #
  module JohnnyWalker
    module Helper
      # dimensions_binary_hash([:a, :b], [  ])      # => 0000 0000
      # dimensions_binary_hash([:a, :b], [:a])      # => 0000 0001
      # dimensions_binary_hash([:a, :b], [:b])      # => 0000 0010
      # dimensions_binary_hash([:a, :b], [:b, :a])  # => 0000 0011
      def dimensions_binary_hash(base, changes)
        
      end
    end
    
    class Base
      include Helper
      
      def initialize(dims)
        @dimensions = dims
        @lower = LowerNode.new
      end
    
      def insert(object)
                
        
      end
    
      def find(*args)
        query = PointQuery.new(*args)
      
        node = walk_to_node(query.slots)
        
      end
    
    private
    
      def walk_to_node(slots)
        curr_node   = @lower
        higher_keys = slots.keys.to_set # i.e. not found yet
        equal_keys  = [].to_set
        
        # On each step we have two complementary lists:
        # * higher_keys - not matched yet
        # * equal_keys - matched keys
        
        # In every node:
        # 1. Update higher_keys, equal_keys (delete from higher_keys, 
        #    add to equal_keys each equal key).
        # 2. Throw away each pointer, where at least one of 
        #    the slots equal current node slot is not in equal_keys.
        #    (drop subdimensional pointers)
        # 3. Throw away each pointer, where at least one of 
        #    the equal_keys slot is higher.
        #    (drop superdimensional pointers)
        # 4. Now we have only current dimension pointers.
        #    We have tree cases and two situations (find or insert).
        #    Cases:
        #    1) Needle is larger than all the pointers.
        #    2) Needle is lower than all the pointers.
        #    3) Needle 
        
        
        # When we stand in a node, we have an array of pointers:
        # 1. If node exactly matches, return it
        # 2. If it matches some of the slots, remove them from not_found_keys
        # 3. Go to the pointer, where most of the (higher_slots)
        
      end
      
    end
    
    

    
    
    class Node
      attr_accessor :nodes, :data, :pointer_conflict_id
      attr_accessor :nodes_higher_keys
      def initialize(data)
        @data  = data
        @vector_info= nil
      end
      
      def find_farthest_node(slots, higher_slots)
        higher_slots_by_node = {}
        @nodes_higher_keys ||= calculate_nodes_higher_keys
        @nodes_higher_keys.each do |node, higher_keys_set|
          higher_keys_set.intersection(higher_slots).size
        end.sort
        
      end
    
    private  
      def calculate_nodes_higher_keys
        hk = {}  
        _data = @data # to speed up var access
        nodes.map do |node|
          set = Set.new
          node.data.each do |k, v|
            set.add(k) unless _data[k] && _data[k] >= v
          end
          hk[node] = set
        end
        hk
      end
      
    end
    
    
    class LowerNode < Node
      def initialize
        p = Pointer.new(self)
        @pointers = [ p ]
      end
    end
    
    # YAGNI!
    #
    # Highly unoptimized version, but thankfully not brainfucking. 
    # Optimized to start playing with.
    class Pointer
      attr_accessor :fixed_slots, 
                    :higher_slots, 
                    :node
      def initialize(node)
        @fixed_slots   = []
        @higher_slots  = []
        @node          = node
      end
      # biggest distance -> first position in pointers.sort
      def <=>(a)
        a.distance <=> self.distance
      end
      def distance
        @distance ||= @higher_slots.size
      end
    end
  end
end
