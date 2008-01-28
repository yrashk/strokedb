module StrokeDB
  class InvertedList
  	include Enumerable
  	
  	# These are not in UTF-8, so we can use 'em
  	# Any kinds of BOM are not supported as well as all encodings except UTF-8 
  	
  	SEPARATOR  = "\xfe" 
  	TERMINATOR = "\xff"
  	
  	def initialize
  	  @list = Skiplist.new({}, nil, nil, false)
  	end
  	
  	def insert(slots, data)
  	  slots.each do |key, value|
  	    value = value.to_s
  	    key = key.to_s
  	    @list.insert(value + SEPARATOR + key + TERMINATOR, data)
	    end
  	end
  	
  	def find(*args)
  	  q = PointQuery.new(*args)
  	  
  	  disjunction = []
  	  q.slots.each do |key, value|
  	    results = []
  	    key = key.to_s
  	    value = value.to_s
  	    prefix = value + SEPARATOR + key + TERMINATOR
  	    node = @list.find_nearest_node(prefix)
  	    while node.key == prefix
  	      results.push node.value
  	      node = node.next
  	    end
  	    disjunction += results
  	    disjunction.uniq!
	    end
	    disjunction
  	end
	end
end
