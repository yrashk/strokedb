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
  	    prefix = value + SEPARATOR + key + TERMINATOR
  	    #debug "Inserting prefix #{prefix.inspect} with #{data.inspect}"
  	    @list.insert(prefix, data)
  	    #debug "Now list is #{@list}"
	    end
  	end
  	
  	def find(*args)
  	  q = PointQuery.new(*args)
  	  total = Set.new
  	  first_pass = true
  	  #debug_header
  	  #debug "Search #{q.slots.inspect}..."
  	  #debug @list.to_s
  	  q.slots.each do |key, value|
  	    results = []
  	    key = key.to_s
  	    value = value.to_s
  	    prefix = value + SEPARATOR + key + TERMINATOR
  	    #debug "Looking for prefix #{prefix.inspect}"
  	    node = @list.find_nearest_node(prefix)
  	    while node.key == prefix
  	      results.push node.value
  	      node = node.next
  	    end
  	    #debug "Results: #{results.inspect}; first pass? #{first_pass}"
  	    total = (first_pass ? results.to_set : (total & results))
  	    first_pass = false
  	    #debug "intermediate total = #{total.inspect}"
	    end
	    #debug "returning total = #{total.inspect}"
	    total
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
        puts "IL DEBUG: #{msg}" if ENV['DEBUG']
      end
    end
    def debug_header
      puts "\n==========================================\n" if ENV['DEBUG']
    end
    
  	
	end
end
