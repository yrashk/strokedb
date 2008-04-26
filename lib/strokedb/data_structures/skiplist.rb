module StrokeDB
  class Skiplist
  	include Enumerable
	
  	attr_accessor :default, :head, :tail, :cut_level, :unique_keys
	  
  	def initialize(data = {}, default = nil, cut_level = nil, unique_keys = true)
  		@default, @cut_level, @unique_keys = default, cut_level, unique_keys

  		@head = HeadNode.new
  		@tail = TailNode.new
  		@head.forward[0] = @tail
  		data.each{|k, v| insert(k, v) }
  	end

  	def insert(key, value, __cheaters_level = nil, __timestamp = nil)
  	  @size_cache = nil
  	  update = Array.new(@head.level)
  	  x = @head
  	  # We have to choose between < and <= only,
  	  # but we go into different branches to keep things fast.  
  	  if @unique_keys
  	    @head.level.downto(1) do |i|
  	      x = x.forward[i-1] while x.forward[i-1] < key
  	      update[i-1] = x
  	    end
	    else
	      @head.level.downto(1) do |i|
  	      x = x.forward[i-1] while x.forward[i-1] <= key
  	      update[i-1] = x
  	    end
      end
  	  x = x.forward[0]
  	  if x.key == key && @unique_keys
  	    x.value = value
  	    x.timestamp = __timestamp
  	    value.skiplist_node_container = x if value.respond_to? :skiplist_node_container=
  	  else
  	    newlevel = __cheaters_level || random_level
  	    newlevel = 1 if empty?
  	    if newlevel > @head.level 
  	      (@head.level + 1).upto(newlevel) do |i|
  	        update[i-1] = @head
          end
        end
        
        x = Node.new(newlevel, key, value, __timestamp)
        value.skiplist_node_container = x if value.respond_to? :skiplist_node_container=
        
        if cut?(newlevel, update[0])
          return new_chunks!(x, update)
        else
          newlevel.times do |i|
            x.forward[i] = update[i].forward[i] || @tail
            update[i].forward[i] = x
          end
        end
      end
  		return self
  	end

    # Finders
    
    def find_node(key = nil)
      x = @head
      @head.level.downto(1) do |i|
  	    x = x.forward[i-1] while x.forward[i-1] < key
  	  end
  	  x = x.forward[0]
	    return (x.key && yield(x.key, key) ? x : nil) if block_given?
  	  return x if x.key == key
  	  nil
    end
    
    def find(key, default = nil)
      (i = find_node(key)) && i.value || default || @default
    end

    def find_nearest_node(key)
      x = @head
      @head.level.downto(1) do |i|
  	    x = x.forward[i-1] while x.forward[i-1] < key
      end
      x = x.forward[0] if (x.forward[0].key == key || x == @head)
      x
    end
    
    def find_nearest(key, default = nil)
      find_nearest_node(key).value || default || @default
    end
        
    def find_all_with_prefix(key)
      results = []
      x = @head
      @head.level.downto(1) do |i|
        x = x.forward[i-1] while x.forward[i-1] < key
      end
      x = x.forward[0]
      # got first 
      while x.key && x.key[0, key.size] == key 
        results << x.value
        x = x.forward[0]
      end
      results
    end
    
        
    def delete(key, default = nil)
      @size_cache = nil
      default ||= @default
      update = Array.new(@head.level)
      x = @head
  	  @head.level.downto(1) do |i|
  	    x = x.forward[i-1] while x.forward[i-1] < key
  	    update[i-1] = x
  	  end
  	  x = x.forward[0]
  	  if x.key == key
        @head.level.times do |i|
          break if update[i].forward[i] != x
          update[i].forward[i] = x.forward[i]
        end
        true while (y = @head.forward.pop) == @tail
        @head.forward.push(y || @tail)
        x.free(self)
        x.value
      else
        default
      end
    end
    
    def first_node
      @head.forward[0]
    end
    
    def size
  		@size_cache ||= inject(0){|c,k| c + 1}
  	end
	
  	def empty?
  	  @head.forward[0] == @tail
  	end

  	# Returns a string representation of the Skiplist.
  	def to_s
  		"#<#{self.class.name} " + 
  		[@head.to_s, map{|node| node.to_s }, @tail.to_s].flatten.join(', ') +
  		">"
  	end
  	def to_s_levels
  		"#<#{self.class.name}:levels " + 
  		[@head.to_s, map{|node| node.level.to_s }, @tail.to_s].flatten.join(', ') +
  		">"
  	end
  	
  	def eql?(skiplist)
  	  zip(skiplist) {|a, b| return false unless a.key == b.key && a.value == b.value }
  	  true
	  end

 	  def each
  	  n = @head.forward[0]
  	  until n.is_a?(TailNode)
  	    yield n
  	    n = n.forward[0]
      end
  	end

    # Only for empty list!
    def raw_insert(data)
      n = @head
      sn = nil
      update = []
      data.each do |item|
        key, value, level, timestamp = yield(item)
        sn = Node.new(level, key, value, timestamp)
        level.times do |i| 
          update[i] ||= @head
          update[i].forward[i] = sn
          sn.forward[i] = @tail 
          update[i] = sn
        end
      end
    end

  private

    # 1/E is a fastest search value
  	PROBABILITY = 1/Math::E
  	MAX_LEVEL   = 32
  
  	def random_level
  		l = 1
  		l += 1 while rand < PROBABILITY && l < MAX_LEVEL
  		return l
  	end
  	
  	def cut?(l, prev)
    	@cut_level && !empty? && l >= @cut_level && prev != @head
  	end

  	def new_chunks!(newnode, update)
  	  # Transposed picture:
  	  #
  	  # head level 8:     - - - - - - - -
  	  # update.size 8:    - - - - - - - -
  	  # ...
  	  # newnode.level 5:  - - - - -
  	  # cut level 3:      - - - 
   	  # regular node:     - 
  	  # regular node:     - -
  	  # ...                        
  	  # tail node:        T T T T T T T T   
  	  #           refs:   A B C D E F G H 
  	  #
  	  # How to cut?
  	  #
      # 0) tail1 = TailNode.new; list2 = Skiplist.new
  	  # 1) newnode.{A, B, C, D, E} := update{A,B,C,D,E}.forward
  	  # 2) update.{all} := tail1 (for current chunk)
  	  # 3) list2.head.{A, B, C, D, E} = new_node.{A, B, C, D, E}
  	  # 4) tail1.next_list = list2
  	  
  	  list2 = Skiplist.new({}, @default, @cut_level)
  	  tail1 = TailNode.new
  	  
  	  newnode.level.times do |i|
  	    # add '|| @tail' because update[i] may be head of a lower level
  	    # without forward ref to tail.
  	    newnode.forward[i] = update[i].forward[i] || @tail
  	    list2.head.forward[i] = newnode
	    end
	    @head.level.times do |i|
	      update[i].forward[i] = tail1
        end
	    tail1.next_list = list2
  	  # return the current chunk and the next chunk
  	  return self, list2
  	end

  	class Node
  		attr_accessor :key, :value, :forward, :timestamp
  		attr_accessor :_serialized_index
  		def initialize(level, key, value,timestamp=nil)
  			@key, @value, @timestamp = key, value, timestamp
  			@forward = Array.new(level)
  		end
  		# this is called when node is thrown out of the list
  		# note, that node.value is called immediately after node.free
  		def free(list)
  		  # do nothing
  		end
  		def level
  		  @forward.size
  		end
  		def <(key)
  		  @key < key
  	  end
  	  def <=(key)
  		  @key <= key
  	  end
  	  def next
  	    forward[0]
  	  end
  	  def to_s
  	    "[#{level}]#{@key}: #{@value}"
  	  end
  	end

  	class HeadNode < Node
  		def initialize
  			super 1, nil, nil
  		end
  		def <(key)
  		  true
  	  end
  	  def <=(key)
  		  true
  	  end
      def to_s
  	    "head(#{level})"
  	  end
  	end
	
  	# also proxy-to-next-chunk node
  	class TailNode < Node
  	  attr_accessor :next_list
  		def initialize
  			super 1, nil, nil
  		end
  		def <(key)
  		  false
  	  end
  	  def <=(key)
  		  false
  	  end
  	  def to_s
  	    "tail(#{level})"
  	  end
  	end
  end
end
