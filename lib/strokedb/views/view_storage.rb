module StrokeDB
  # This is a base class for view storages.
  # It provides some basic methods relying on @list instance variable.
  # #initialize, #exists? and #clear! methods must be overriden in a subclass. 
  #
  class ViewStorage
    attr_reader :options
    
    def initialize(options = {})
    end
    
    # TODO: refactor this API
    #
    def set_options(options)
      @options = options
    end
        
    # 
    #
    def find(start_key, end_key, limit, offset, reverse, with_keys)
      @list.search(start_key, end_key, limit, offset, reverse, with_keys)
    end
        
    # 
    #
    def replace(old_pairs, new_pairs)
      old_pairs.each do |pair|
        key, value = pair
        @list.delete(key) if @list.find(key)
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
      raise "Not implemented in an abstract class. See subclasses."
    end
    
    #
    #
    def clear!
      raise "Not implemented in an abstract class. See subclasses."
    end
    
    def empty?
      @list.empty?
    end
    
  end
end
