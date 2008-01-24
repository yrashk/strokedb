module StrokeDB
  class Chunk
    attr_accessor :skiplist, :next_chunk, :prev_chunk, :uuid, :cut_level 
    
    def initialize(cut_level)
      @skiplist, @cut_level = Skiplist.new({}, nil, cut_level), cut_level
    end
    
    def insert(uuid, raw_doc, __cheaters_level = nil)
      @uuid ||= uuid
      a, new_list = skiplist.insert(uuid, raw_doc, __cheaters_level)
      if new_list
        tmp = Chunk.new(@cut_level)
        tmp.skiplist = new_list
        tmp.next_chunk = @next_chunk if @next_chunk
        @next_chunk = tmp
        @next_chunk.uuid = uuid
      end
      # we don't update self.uuid 'cos don't like to change filename
      # anyway, we would have to do it for the very first chunk only
      [self, @next_chunk]
    end

    def find(uuid, default = nil)
      skiplist.find(uuid, default)
    end
    
    def find_nearest(uuid, default = nil)
      skiplist.find_nearest(uuid, default)
    end
    
    def size
      skiplist.size
    end
    
    def each(&block)
      skiplist.each &block
    end
        
  	# Raw format

    # TODO: lazify
  	def self.from_raw(raw)
  	  chunk = Chunk.new(raw['cut_level'])
  	  chunk.uuid       = raw['uuid']
  	  chunk.next_chunk = nil

      chunk.skiplist.raw_insert(raw['nodes']) do |rn|
  	    [rn['key'], rn['value'], rn['forward'].size]
  	  end
  	  chunk
  	end
 
  	def to_raw
  	  # enumerate nodes
  	  skiplist.each_with_index do |node,i|
     	  node._serialized_index = i
      end
      
      # now we know keys' positions right in the nodes
  	  nodes = skiplist.map do |node|
        {
          'key'     => node.key,
          'forward' => node.forward.map{|n| n._serialized_index || 0 },
          'value'   => node.value
        }
      end
      {
        'nodes'     => nodes, 
        'cut_level' => @cut_level, 
        'uuid'      => @uuid,
        # TODO: may not be needed
        'next_uuid' => next_chunk ? next_chunk.uuid : nil
      }
  	end
  	
  	def eql?(chunk)
  	 chunk.uuid == @uuid && chunk.skiplist.eql?(@skiplist)
  	end
  	
  end
end
