module StrokeDB
  class InvertedList
    module Debug
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
          puts "IL DEBUG: #{msg}" if ENV['DEBUG']
        end
      end
      def debug_header
        puts "\n==========================================\n" if ENV['DEBUG']
      end
    end
    include Debug    
  	include Enumerable
  	
  	# These are not in UTF-8, so we can use them as separators
  	# Any kinds of BOM are not supported as well as all encodings except UTF-8 
  	
  	SEPARATOR  = "\xfe" # consider sort order!
  	TERMINATOR = "\xff"
  	
  	attr_accessor :default, :head, :tail, :cut_level

  	def initialize(cut_level = nil)
  		@cut_level = cut_level
  		@head = HeadNode.new
  		@tail = TailNode.new
  		@head.forward[0] = @tail
  	end

  	def insert(slots, data, __cheaters_level = nil)
  	  #debug_header
  	  slots.each do |key, value|
  	  #  debug "inserting slot: key: #{key}, value:#{value.inspect}"
  	  #  debug "list: #{self}"
  	    value = value.to_s
  	    key = key.to_s
  	    prefix = value + SEPARATOR + key + TERMINATOR
  	    #debug "Inserting prefix #{prefix.inspect} with #{data.inspect}"
  	    insert_attribute(prefix, data, __cheaters_level)
  	    #debug "Now list is #{self}"
	    end
  	end

  	def insert_attribute(key, value, __cheaters_level = nil)
  	  #debug "insert: key: #{key.inspect}, value = #{value.inspect}"
      
  	  @size_cache = nil
  	  update = Array.new(@head.level)
  	  base_keys = [@head.prefix.dup]*@head.level
  	  x = @head
	    bkey = @head.prefix
	    i = @head.level-1
	    #(@head.level-1).downto(0) do |i|
	    while i >= 0 
	      bkey = base_keys[i + 1] || @head.prefix
	      while x.forward[i].less(key, i, bkey)
	        #puts "Insert walking: i: #{i}, x: #{x}, x.forward[i]: #{x.forward[i]} (less than #{key.inspect})"
	        x = x.forward[i]
	        #puts "DECOMPRESS[#{i}]: #{x.compressed_keys[i].inspect}, base #{bkey.inspect} "
	        bkey = x.decompress_key(x.compressed_keys[i], bkey)
        end
        base_keys[i] = bkey
        #puts ">> (inserting #{key.inspect}) base_keys[#{i}] = #{base_keys.inspect}"
	      update[i] = x
	      i -= 1
	    end
	    
	    #debug "x: #{x}; x.forward[0] = #{x.forward[0]}"
	    
  	  x = x.forward[0]
  	  if x.equal(key, 0, bkey)
  	    x.values.push value
  	  else
  	    newlevel = __cheaters_level || random_level
  	    newlevel = 1 if empty?
  	    # enlarge update vector
  	    if newlevel > @head.level 
  	      (@head.level + 1).upto(newlevel) do |i|
  	        update[i-1]              = @head
  	        update[i-1].forward[i-1] = @tail
  	        base_keys[i-1]           = ""
          end
        end

        x = Node.new(newlevel, key, value)

        if cut?(newlevel, update[0])
          raise "Not implemented yet!"
          return new_chunks!(x, update)
        else
          x.insert_after(update, base_keys)
        end
      end
  		return self
  	end

    # Finders
    
    def find(*args)
      #debug_header
      #debug "list is: #{self}"
      #debug "query is #{args.inspect}"
  	  q = PointQuery.new(*args)
  	  total = Set.new
  	  first_pass = true
  	  #debug_header
  	  #debug "Search #{q.slots.inspect}..."
  	  #debug to_s
  	  q.slots.each do |key, value|
  	    results = []
  	    key = key.to_s
  	    value = value.to_s
  	    prefix = value + SEPARATOR + key + TERMINATOR
  	    #debug "Looking for prefix #{prefix.inspect}"
  	    if node = find_node(prefix)
  	      results += node.values
  	    end
  	    #debug "Results: #{results.inspect}; first pass? #{first_pass}"
  	    total = (first_pass ? results.to_set : (total & results))
  	    first_pass = false
  	    #debug "intermediate total = #{total.inspect}"
	    end
	    #debug "returning total = #{total.inspect}"
	    total
  	end
  	
    def first_node
      @head.forward[0]
    end
    
    def find_node(key = nil)
      base_keys = [@head.prefix.dup]*@head.level
  	  x = @head
	    bkey = @head.prefix
	    (@head.level-1).downto(0) do |i|
	      bkey = base_keys[i + 1] || @head.prefix
	      while x.forward[i].less(key, i, bkey)
	        #debug "Find walking: i: #{i}, x: #{x}, x.forward[i]: #{x.forward[i]}"
	        x = x.forward[i]
	        bkey = x.decompress_key(x.compressed_keys[i], bkey)
        end
        base_keys[i] = bkey
	    end
  	  x = x.forward[0]
  	  return x if x.equal(key, 0, bkey)
  	  nil
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
  		[@head.to_s, 
  		  map{|node| node.to_s }, 
  		  @tail.to_s].flatten.join(', ') +
  		">"
  	end
  	def to_s_levels
  		"#<#{self.class.name}:levels " + 
  		[@head.to_s, 
  		  map{|node| node.level.to_s }, 
  		  @tail.to_s].flatten.join(', ') +
  		">"
  	end

  	def eql?(skiplist)
  	  zip(skiplist) {|a, b| return false unless a.key == b.key && a.value == b.value }
  	  true
	  end

 	  def each
  	  n = @head.forward[0]
  	  k = @head.prefix
  	  until TailNode === n
  	    k = n.decompress_key(n.compressed_keys[0], k)
  	    yield(k, n)
  	    n = n.forward[0]
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
    # TODO
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
  	  include Debug
  		attr_accessor :values, :forward, :compressed_keys, :key
  		attr_accessor :_serialized_index
  		def initialize(level, key, value)
  			@values   = [value]
  			@forward  = Array.new(level)
  			@compressed_keys = Array.new(level)
  			@key = key
  		end

      def insert_after(prev_nodes, base_keys)
        # puts "-----------------------"
        # puts "Inserting after (level = #{level}): "
        # pp :key => @key
        # pp :prev_nodes => prev_nodes.map{|n| n.nil? ? n : n.key }
        # pp :base_keys  => base_keys
        
        key = @key # 30% faster than @key
        @forward.each_with_index do |fwd, i|
          # update compressed keys
          @compressed_keys[i] = compress_key(key, base_keys[i])
          # copy forward links
          fwd = prev_nodes[i].forward[i]
          # update forward keys
          unless TailNode === fwd
            fwd.compressed_keys[i] = compress_key(
                                         decompress_key(
                                          fwd.compressed_keys[i], base_keys[i]
                                         ), key)
          end
          @forward[i] = fwd
          # set previous forwards to self
          prev_nodes[i].forward[i] = self
        end
      end
      
  		def level
  		  @forward.size
  		end
  		
  		# HOT SPOTS! (ruby is increadibly slower in this place)
  		
  		def compress_key(key, base)
        j = 0
        j += 1 while key[j] && key[j] == base[j]
        [ j, key[j, key.size] ]
   		end
  		def decompress_key(compressed_key, base)
  		  base[ 0, compressed_key[0] ] + compressed_key[1]
  		end
  		# Iterational methods (valid in search context only)
  		# ai_ because "array index" == level - 1
  		def less(key, ai_level, base)
  		  # > because #key_spaceship is for key. But #less is for self.
  		  key_spaceship(key, @compressed_keys[ai_level], base) > 0
  	  end
  	  def equal(key, ai_level, base)
  	    key_spaceship(key, @compressed_keys[ai_level], base) == 0
  	  end
  	  
  	  def key_spaceship(key, compressed_key, base)
  #	    puts "KEY COMP.: #{key[ compressed_key[0], key.size ].inspect} <=> #{compressed_key[1]} => #{key[ compressed_key[0], key.size ] <=> compressed_key[1]}"
        l  = compressed_key[0]
        kp = key[  0, l ]
        bp = base[ 0, l ]
        return kp <=> bp if kp != bp
  	    key[ l, key.size ] <=> compressed_key[1]
	    end  	  
      
  	  def next
  	    forward[0]
  	  end
  	  def to_s
  	    "[#{level}](#{@compressed_keys[0][0].inspect}:#{@compressed_keys[0][1].inspect}): #{@values.inspect}"
  	  end
  	end

  	class HeadNode < Node
  	  attr_accessor :prefix
  		def initialize(prefix = "")
  		  @prefix = prefix
  		  @value = nil
  		  @forward = [nil]
  		end
  		def key
  		  @prefix
		  end
      def to_s
  	    "head([#{level}] #{@prefix.inspect})"
  	  end
  	end

  	# also proxy-to-next-chunk node
  	class TailNode < Node
  	  attr_accessor :next_list
  		def initialize
  		end
  		def less(key, ai_level, b) # ai_ because "array index" == level - 1
  		  false
  	  end
  	  def equal(key, ai_level, b)
  	    false
  	  end
  	  def to_s
  	    "tail"
  	  end
  	end

	end
end
