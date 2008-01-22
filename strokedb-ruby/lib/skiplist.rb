module StrokeDB
  class Skiplist
  	include Enumerable
	
  	attr_reader   :size
  	attr_accessor :default, :head, :tail
	
  	def initialize(data = {}, default = nil, cut_level = nil)
  		@default, @size, @cut_level = default, 0, cut_level

  		@head = HeadNode.new
  		@tail = TailNode.new
  		@head.forward[0] = @tail
		
  		data.each{|k, v| insert(k, v) }
  	end

  	def insert(key, value, cheaters_level = nil)
  	  update = Array.new(@head.level)
  	  x = @head
  	  @head.level.downto(1) do |i|
  	    x = x.forward[i-1] while x.forward[i-1] < key
  	    update[i-1] = x
  	  end
  	  if x.key == key
  	    x.value = value
  	  else
  	    @size += 1
  	    newlevel = cheaters_level || random_level
  	    newlevel = @cut_level if @size == 1 && @cut_level && newlevel < @cut_level
  	    if newlevel > @head.level 
  	      (@head.level + 1).upto(newlevel) do |i|
  	        update[i-1] = @head
          end
        end
        
        x = Node.new(newlevel, key, value)
        
        if cut?(newlevel)
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

    def find(key, default = nil)
      default ||= @default
      x = @head
      @head.level.downto(1) do |i|
  	    x = x.forward[i-1] while x.forward[i-1] < key
  	  end
  	  x = x.forward[0]
  	  return x.value if x.key == key
  	  default
    end
  
    def delete(key, default = nil)
      default ||= @default
      update = Array.new(@head.level)
      x = @head
  	  @head.level.downto(1) do |i|
  	    x = x.forward[i-1] while x.forward[i-1] < key
  	    update[i-1] = x
  	  end
  	  x = x.forward[0]
  	  if x.key == key
  	    @size -= 1
        @head.level.times do |i|
          break if update[i].forward[i] != x
          update[i].forward[i] = x.forward[i]
        end
        true while (y = @head.forward.pop) == @tail
        @head.forward.push y if y
        x.free(self)
        x.value
      else
        default
      end
    end

  	def length
  		@size
  	end
	
  	def empty?
  	  @size == 0
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
	
  	def each
  	  n = @head.forward[0]
  	  until TailNode === n
  	    yield n
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
  	
  	def cut?(l)
    	@cut_level && @size > 1 && l >= @cut_level
  	end
  	
  	def new_chunks!(newnode, update)
  	  chunk = Skiplist.new({}, @default, @cut_level)
  	  
  	  # 1. 'update' array contains refs to newnode and to the tail
  	  
  	  
  	  # return the current chunk and the next chunk
  	  return self; #, chunk
  	end

  	class Node
  		attr_accessor :key, :value, :forward
  		def initialize(level, key, value)
  			@key, @value = key, value
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
  	  def to_s
  	    "#{key}: #{value}"
  	  end
  	end

  	class HeadNode < Node
  		def initialize
  			super 1, nil, nil
  		end
  		def <(key)
  		  true
  	  end
  	  def to_s
  	    "head(#{self.level})"
  	  end
  	end
	
  	# also proxy-to-next-chunk node
  	class TailNode < Node
  		def initialize
  			super 1, nil, nil
  		end
  		def <(key)
  		  false
  	  end
  	  def to_s
  	    "tail(#{self.level})"
  	  end
  	end
  end
end
