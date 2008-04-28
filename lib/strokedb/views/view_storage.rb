module StrokeDB
  class ViewStorage
    attr_reader :storage, :options, :exists
    
    def initialize(options = {})
      # TODO: find out whether the view indexfile exists and read
      #       its options
      @list = SimpleSkiplist.new
    end
    
    def set_options(options)
      # if exists? && self.options != options
      #   raise StandardError, "Couldn't change options for an existing storage!"
      # end
      
      @options = options
      
    end
        
    # 
    #
    def find(start_key, end_key, key, limit, offset, reverse, with_keys)
      start_key = end_key = key if key
      @list.search(start_key, end_key, limit, offset, reverse, with_keys)
    end
        
    # 
    #
    def replace(old_pairs, new_pairs)
      old_pairs.each do |pair|
        key, value = pair
        @list.insert(key,nil) if @list.find(key)
      end
      insert(new_pairs)
    end
    
    #
    #
    def insert(new_pairs)
      new_pairs.each do |pair|
        key, value = pair
        @list.insert(key, value)
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
      @list = SimpleSkiplist.new
    end
    
    def empty?
      @list.empty?
    end
    
  end
end
