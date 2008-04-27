module StrokeDB
  class ViewStorage
    attr_reader :storage, :options, :exists
    
    def initialize(options = {})
      # TODO: find out whether the view indexfile exists and read
      #       its options
      @skiplist = SimpleSkiplist.new
    end
    
    def set_options(options)
      if exists? && self.options != options
        raise StandardError, "Couldn't change options for an existing storage!"
      end
      
      @options = options
      
    end
        
    # 
    #
    def oleganza_find(start_key, end_key, limit, offset, reverse, with_keys)
      @skiplist.search(start_key, end_key, limit, offset, reverse, with_keys)
    end
    
    #
    #
    def find(start_key, end_key, key, limit, offset, reverse, with_keys)
      start_key = end_key = key if start_key.nil? && end_key.nil? 
      # Please note that below algorithm will most probably be eventually replaced by a new skiplist Oleg Andreev works on currently
      start_key = @skiplist.first_key unless start_key
      current_key = start_key
      offset ||= 0
      
      items = []
      item = @skiplist.find_nearest_node(current_key)
      
      offset.times do 
        item = item[0][0] # next node
      end
      
      until item.nil?
        items << (with_keys ? [item[1],item[2]] : item[2]) # [1] is a node_key [2] is a node_value
        break if (current_key = item[1]) == end_key
        break if items.size == limit
        item = item[0][0] # next node
      end

      items
    end
    
    # 
    #
    def replace(old_pairs, new_pairs)
      old_pairs.each do |pair|
        key, value = pair
        @skiplist.insert(key,nil) if @skiplist.find(key)
      end
      insert(new_pairs)
    end
    
    #
    #
    def insert(new_pairs)
      new_pairs.each do |pair|
        key, value = pair
        @skiplist.insert(key, value)
      end
    end
    
    #
    #
    def exists?
      true
    end
    
    #
    #
    def clear!
      @skiplist = SimpleSkiplist.new
    end
    
    def empty?
      @skiplist.empty?
    end
    
  end
end
