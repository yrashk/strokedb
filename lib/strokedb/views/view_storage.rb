module StrokeDB
  class ViewStorage
    attr_reader :storage, :options, :exists
    
    def initialize(options = {})
      # TODO: find out whether the view indexfile exists and read
      #       its options
    end
    
    def set_options(options)
      if exists? && self.options != options
        raise StandardError, "Couldn't change options for an existing storage!"
      end
      
      self.options = options
      
    end
        
    #
    #
    def find(start_key, end_key, key, limit, offset, reverse, with_keys)
      
    end
    
    # 
    #
    def replace(old_pairs, new_pairs)
      
    end
    
    #
    #
    def insert(new_pairs)
      
    end
    
    #
    #
    def exists?
      
    end
    
    #
    #
    def clear!
      
    end
  end
end
