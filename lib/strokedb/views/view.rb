module StrokeDB
  View = Meta.new do 
    on_initialization do |viewdoc|
      unless viewdoc["name"]
        raise ArgumentError, "View name must be specified!"
      end
      
      # pass viewdoc into initialization block:
      # my_view = View.new(){ |view| ... }
      viewdoc.instance_variable_get(:@initialization_block).call(viewdoc)
    end
    
    DEFAULT_FIND_OPTIONS = {
      :startkey   => nil,
      :endkey     => nil,
      :count      => nil,
      :descending => false,
      :skip       => nil,
      :key        => nil,   # equivalent to set startkey and endkey to the same value
      :with_keys  => false  # returns [key, value] pairs instead of just values
    }.freeze
    
    # TODO
    # Returns true if the index file is valid and will be used
    # by #find method.
    #
    def index_exists?
      # TODO: check the existance of the index
    end
    
    # 
    #
    def find(options)
      options = DEFAULT_FIND_OPTIONS.merge(options)
      
      if k = options[:key]
        options[:startkey] = k
        options[:endkey]   = k
      end
      
      # Mode 1. startkey, count (skip)
      # Mode 2. startkey..endkey
      
      #storage = 
      
    end
    
    # This is used by the storage to update index
    # with a new version of document
    def insert(doc) #:nodoc:
      pairs = map(doc)
      
      # TODO: insert pairs into the storage
      
    end
    
    
    # These are defaults (to by overriden in View.new{|v| ... })
    
    def map(doc)
      raise "#map method is not defined for a view #{self['name']}!"
    end
    
    def encode_key(json_key)
      DefaultKeyEncoder.encode(json_key)
    end
    
    def decode_key(string_key)
      DefaultKeyEncoder.decode(string_key)
    end
    
    # By default, there's no split hinting 
    def split_by(json_key)
      json_key
    end
  end
end


