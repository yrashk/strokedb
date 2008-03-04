module StrokeDB
  class Chunk
    attr_accessor :skiplist, :next_chunk, :prev_chunk, :uuid, :cut_level, :timestamp 
    attr_accessor :next_chunk_uuid
    attr_accessor :store_uuid 
    def initialize(cut_level)
      @skiplist, @cut_level = Skiplist.new({}, nil, cut_level), cut_level
    end
    
    def insert(uuid, raw_doc, __cheaters_level = nil, __lamport_timestamp = nil)
      @uuid ||= uuid
      __cheaters_level ||= $DEBUG_CHEATERS_LEVEL
      a, new_list = skiplist.insert(uuid, raw_doc, __cheaters_level, __lamport_timestamp)
      if new_list
        tmp = Chunk.new(@cut_level)
        tmp.skiplist = new_list
        tmp.next_chunk = @next_chunk if @next_chunk
        @next_chunk = tmp
        @next_chunk.uuid = uuid
      end
      [self, @next_chunk]
    end
    
    def delete(uuid)
      skiplist.delete(uuid)
    end

    def find(uuid, default = nil)
      skiplist.find(uuid, default)
    end
    
    def find_node(uuid)
      skiplist.find_node(uuid)
    end
    
    def find_nearest(uuid, default = nil)
      skiplist.find_nearest(uuid, default)
    end
    
    # Finds next node across separate chunks
    def find_next_node(node)
      chunk = self
      node2 = node.next
      if node2.is_a?(Skiplist::TailNode)
        chunk = chunk.next_chunk
        unless chunk.nil?
          node2 = chunk.first_node
        else
          node2 = nil
        end
      end
      node2
    end
    
    
    def first_uuid
      skiplist.first_node.key
    end

    def first_node
      skiplist.first_node
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
      chunk.next_chunk_uuid = raw['next_uuid']
      chunk.timestamp = raw['timestamp']
      chunk.store_uuid = raw['store_uuid']
      chunk.skiplist.raw_insert(raw['nodes']) do |rn|
  	    [rn['key'], rn['value'], rn['forward'].size, rn['timestamp']]
  	  end
  	  yield(chunk) if block_given?
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
          'value'   => node.value,
          'timestamp' => node.timestamp
        }
      end
      {
        'nodes'     => nodes, 
        'cut_level' => @cut_level, 
        'uuid'      => @uuid,
        # TODO: may not be needed
        'next_uuid' => next_chunk ? next_chunk.uuid : nil,
        'timestamp' => @lamport_timestamp,
        'store_uuid'        => @store_uuid
      }
  	end
  	
  	def eql?(chunk)
  	 chunk.uuid == @uuid && chunk.skiplist.eql?(@skiplist)
  	end
  	
  end
end
