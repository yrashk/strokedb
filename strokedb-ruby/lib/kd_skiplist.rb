module StrokeDB
  
  #  k-dimensional skiplist, version 2 
  # (according to Bradford G. Nickerson,
  #  Skip List Data Structures for Multidimensional Data)
  class KDSkiplist2
    attr_reader :unique_key
    def initialize(unique_key = nil)
      @unique_key = unique_key
      @dimensions = []
      @lists = {}
    end
    
    # Inserts some object to a k-d list.
    # Relies on a #[] and #each method to access dimensions slots.
    def insert(object, __cheater_levels = nil)
      debug_header
      debug "Inserting #{object.inspect}"
      locations = {}
      
      # Allocating nodes per each dimension
      object.each do |k, v|
        node = Node.new(object[k], object)
        locations[k] = node
        # build dimensions dynamically
        unless @lists[k]
          debug "Creating skiplist #{k.inspect}"
          @lists[k] = Skiplist.new({}, nil, nil, k == @unique_key)
          @dimensions.push k
        end
        @lists[k].insert(node.key, node, __cheater_levels ? __cheater_levels[k] : nil)
      end
      
      # Add references to all nodes to their copies in other dimensions
      object.each do |k1, v2|
        object.each do |k2, v2|
          unless k1 == k2 
            debug "Cross-dimensions reference: #{locations[k1]}.pointers[#{k1.inspect}] = #{locations[k2].skiplist_node_container} [#{k2.inspect}]"
            locations[k1].pointers[k2] = locations[k2].skiplist_node_container 
          end
        end
      end
    end
    
    # Find a subset of data in a multidimensional range.
    # If range is not given for some dimension, it is 
    # assumed to be (-∞; +∞)
    # Semi-infinite range can be applied in such way:
    #
    #   :slot => [nil, 42 ]  # => (-∞; 42]
    #   :slot => [42,  nil]  # => [42; +∞) 
    #   :slot => [nil, nil]  # => (-∞; +∞) 
    #
    # Thus, nil is not a valid value for a slot. 
    # Slot with a nil value is considered missing.
    # 
    # Examples:
    #  list.find(:x => 10..20,   :y => 30..70)    # ranges
    #  list.find(:x => [10, 20], :y => [30, nil]) # :y is within [30; +∞)
    #  list.find(:x => 10)                        # :x is within [10; 10]
    #
    # Options example:
    #  list.find({:__meta__ => 'Article', :author => '@#oleg-andreevs-uuid'}, 
    #            :order_by       => :created_at,
    #            :reversed_order => true,
    #            :limit          => 10)
    #
    # Returns an Array instance (empty when nothing found).
    # 
    def find(ranges, options = {})
      debug_header
      debug "find: #{ranges.inspect}, options are #{options.inspect}"
      # 0. Optimization
      return find_optimized(ranges, options) unless options.delete(:non_optimized)
      
      # 1. Prepare input: options and ranges
      order_by       = options.delete(:order_by)
      reversed_order = options.delete(:reversed_order)
      limit          = options.delete(:limit)
      offset         = options.delete(:offset)
      raise ":reversed_order, :limit and :offset are not supported!" if reversed_order || limit || offset
      # Convert single-values to ranges
      ranges.each {|d, v| ranges[d] = [v, v] unless !(String === v) && Enumerable === v }
      ranges[order_by] ||= [ nil, nil ] if order_by
      results = []
      
      iterators = {} # current node in each key list
      hyperkey  = {} # current key values for each key ("k-d key")
      
      # 2. Determine location of the smallest element in each range (iterators)
      ranges.each do |dim, range|
        f = range.first
        iterators[dim] = f.nil? ? @lists[dim].first_node : @lists[dim].find_node(f){|k1,k0| k1 >= k0}
        # return if no data with slot k found
        unless iterators[dim] 
          debug "#{dim.inspect} -> #{range.inspect} not found in #{@lists[dim].to_s}. Range is #{range}"
          return []
        end
        hyperkey[dim] = iterators[dim].key
      end
      
      dimensions  = ranges.keys
      dimension   = dimensions.first
      dimension_i = 0
      i = iterators[dimension]
      # two utility vars for faster hyperkey <=> hyperrange.higher comparison
      is_greater_by_dimensions = []
      lower_keys_counter = ranges.size
      while lower_keys_counter > 0
        debug "#{lower_keys_counter} dimensions to test. Base is #{dimension.inspect}."
        d_i = dimension_i
        in_range = false
        begin
          range = ranges[dimension]
          hyperkey[dimension] = kd = i.key
          debug "Testing #{kd.inspect} against #{range.inspect}"
          # update hyperkey comparison data
          higher  = (kd.nil? || range.higher?(kd))
          greater = is_greater_by_dimensions[dimension_i]
          if higher && !greater
            debug "Dimension #{dimension.inspect} iterator is outside the range #{range.inspect}. #{lower_keys_counter - 1} dimensions left."
            lower_keys_counter -= 1
            is_greater_by_dimensions[dimension_i] = true
          elsif !higher && greater
            debug "Dimension #{dimension.inspect} iterator returned to #{range.inspect} or lower. #{lower_keys_counter + 1} dimensions left."
            lower_keys_counter += 1
            is_greater_by_dimensions[dimension_i] = false
          end
          
          # kd may be boolean
          if kd.nil?
            debug "Key is nil (terminator). Exiting in-range loop."
            break
          end
          
          # if outside the range, try next item in current dimension
          if range.outside?(kd)
            debug "Dimension #{dimension.inspect} iterator #{kd.inspect} is outside the range #{range.inspect}. Going to next iterator."
            in_range = false
            i = i.next
            break
          end
          
          in_range = true
          debug "Switching dimension: #{dimension.inspect} => #{dimensions[(dimension_i + 1) % dimensions.size].inspect}. Base is #{dimensions[d_i].inspect}."
          # Switch dimension on current node
          dimension_i = (dimension_i + 1) % dimensions.size
          dimension = dimensions[dimension_i]
         # debug "Switching i = #{i.to_s} (=>) i.value.pointers[#{dimension.inspect}] = #{i.value.pointers[dimension].inspect}"
          i_ = i.value.pointers[dimension]
          unless i_
            debug "Warning: iterator #{i} doesn't have a #{dimension.inspect} pointer!"
          end
          i = i_ || i # nil only if ref to itself
        end until d_i == dimension_i
        
        # kd may be boolean
        if kd.nil?
          debug "Key is nil (terminator). Exiting big loop."
          break
        end
        
        if in_range
          debug "In range! Adding node #{i.value.data.inspect}."
          results << i.value.data # skiplist node is wrapped into kdnode
          i = i.next
        else
          debug "Not in range! Node is #{i.value}."
        end
      end
      debug "Big loop exited. #{lower_keys_counter} non-tested dimensions."
      debug "Results: #{results.size}; unique: #{results.uniq.size}"
      # results may contain duplicate values
      results.uniq 
    end
    
    # This is stub. Optimized version is in optimizations/find.rb
    def find_optimized(ranges, options)
      find(ranges, options.merge(:non_optimized => true))
      # TODO:
      # write_find_optimization!(ranges, options)
      # find_optimized(ranges, options)
    end
        
    def to_s
      "#<#{self.class.name} " +
      "@dimensions=#{@dimensions} " +
      "@lists=[#{@lists.join(", ")}]>"
    end
    
    def debug(msg)
      if block_given?
        begin
          out = []
          out << "\n\n---- Start of #{msg} -----"
          yield(out)
          return
        rescue => e
          puts out.join("\n")
          puts "---- End of #{msg}: exception! -----"
          puts e
          puts e.backtrace.join("\n") rescue nil
          puts "----"
          raise e
        end
      else
        puts "KDSL DEBUG: #{msg}" if ENV['DEBUG']
      end
    end
    def debug_header
      puts "\n==========================================\n" if ENV['DEBUG']
    end
    
    
    # Utility classes
    
    class Node
      attr_accessor :key, :data, :pointers, :skiplist_node_container
      def initialize(key, data)
        @key      = key
        @data     = data
        @pointers = {}
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

module Enumerable
  def higher?(key)
    !last.nil? && last < key 
  end
  def lower?(key)
    !first.nil? && first > key 
  end
  def outside?(key)
    higher?(key) or lower?(key)
  end
end


