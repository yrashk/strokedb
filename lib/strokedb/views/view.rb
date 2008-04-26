module StrokeDB
  View = Meta.new do 
    
    DEFAULT_VIEW_OPTIONS = {
      # Declare the size for a key to use optimized index file
      # (size in bytes).
      "fixed_size_key"   => nil,
      
      # By default, view index stores dpointers to the actual data value.
      # If you need to store some value in the index file, you may set this to
      # true or a particular size (in bytes, for fixed-length data).
      # Note: optimized storage is used when both keys and values 
      # are the fixed length. I.e. "inline" is false or an integer and 
      # "fixed_size_key" is an integer.
      "inline"           => false,  # Integer 
      
      # strategy determines whether to index HEADs or particular versions
      # When :heads is used, previous versions are removed from the index.
      "strategy"         => "heads", # heads|versions
      
      # what to do when the key is duplicated: add to list (append|prepend),
      # overwrite or don't do anything ("skip").
      "on_duplicate_key" => "append" # append|prepend|skip|overwrite
    }
    
    on_initialization do |viewdoc|
      unless viewdoc["name"]
        raise ArgumentError, "View name must be specified!"
      end
      
      viewdoc.reverse_update_slots(DEFAULT_VIEW_OPTIONS)
    
      # pass viewdoc into initialization block:
      # my_view = View.new(){ |view| ... }
      if initialization_block = viewdoc.instance_variable_get(:@initialization_block)
        initialization_block.call(viewdoc)
      end
    end
    
    DEFAULT_FIND_OPTIONS = {
      :start_key  => nil,   # start search with a given prefix
      :end_key    => nil,   # stop search with a given prefix
      :limit      => nil,   # retrieve at most <N> entries
      :offset     => nil,   # skip a given number of entries
      :reverse    => false, # reverse search direction and meaning of start_key & end_key 
      :key        => nil,   # prefix search (start_key == end_key)
      :with_keys  => false  # returns [key, value] pairs instead of just values
    }.freeze
    
    # TODO
    # Returns true if the index file is valid and will be used
    # by #find method.
    #
    def index_exists?
      # TODO: check the existance of the index
    end
    
    # Finds 
    #
    def find(options)
      options = DEFAULT_FIND_OPTIONS.merge(options)
      
      start_key  = options[:start_key]
      end_key    = options[:end_key]
      key        = options[:key]
      limit      = options[:limit]
      offset     = options[:offset]
      reverse    = options[:reverse]
      with_keys  = options[:with_keys]
      
      ugly_find(start_key, end_key, key, limit, offset, reverse, with_keys)
    end
    
    # Ugly find accepts fixed set of arguments and works a bit faster, 
    # than a regular #find(options = {}) [probably insignificantly faster, TODO: check this]
    # Some arguments can be nils.
    # 
    def ugly_find(start_key, end_key, key, limit, offset, reverse, with_keys)
      
      # Mode 1. startkey, count (skip)
      # Mode 2. startkey..endkey
      # Mode 3. key, count (skip) - prefix search
      
      if key 
        end_key = start_key = key
      end
      
      array = storage.find(encode_key(start_key), 
                           end_key && encode_key(end_key), 
                           limit, 
                           offset, 
                           reverse, 
                           with_keys)
      
      if with_keys
        array.map do |ekey, evalue|
          [ decode_key(ekey), decode_value(evalue) ]
        end
      else
        array.map do |evalue|
          decode_value(evalue)
        end
      end
    end
      
    # This is used by the storage to update index with a new version of document.
    # Viewdoc contains a "strategy" slot, defining a strategy for index updates.
    #
    # * "heads" strategy removes previous version from the index.
    # * "versions" strategy just adds new version to the index.
    #
    # See meta/papers/views.txt for more info.
    #
    def update(doc)
      # Strategy is a constant for a particular document version,
      # so we just redefine an #update method for faster dispatching.
      if self["strategy"] == "heads"
        class << self
          alias_method :update, :update_head
          public :update
        end
      else
        class << self
          alias_method :update, :update_version
          public :update
        end
      end
      update(doc)
    end
    
    # Remove a previous version, add a new one,
    # pass UUID as a key to #map        
    #
    def update_head(doc) #:nodoc
      prev = doc.versions.previous
      old_pairs = map_with_encoding(prev.uuid, prev)
      new_pairs = map_with_encoding(doc.uuid,  doc)
      storage.replace(old_pairs, new_pairs)
    end
    private :update_head
    
    # Add a new version to the index,
    # pass [UUID, VERSION] as a key to #map
    #
    def update_version(doc) #:nodoc
      new_pairs = map_with_encoding([doc.uuid, doc.version],  doc)
      storage.insert(new_pairs)
    end
    private :update_version
        
    def map_with_encoding(key, value)
      (map(key, value) || []).map do |k, v|
        [encode_key(k), encode_value(v)]
      end
    end
    private :map_with_encoding
    

    # These are defaults (to by overriden in View.new{|v| ... })
    
    def map(key, value)
      raise InvalidViewError, "#map method is not defined for a view #{self['name']}!"
    end
    
    def encode_key(json_key)
      DefaultKeyEncoder.encode(json_key)
    end
    
    def decode_key(string_key)
      DefaultKeyEncoder.decode(string_key)
    end
    
    def encode_value(value)
      # TODO:
      # Calculate a dpointer if this is a document.
      # Or find/create a blob and emit a dpointer to it.
    end
    
    def decode_value(evalue)
      # TODO: 
      # evalue is a dpointer, retrieve the stuff
      # out of it. If it contains a document prefix,
      # instantiate a document.
    end
    
    # By default, there's no split hinting 
    def split_by(json_key)
      json_key
    end
  end
  
  Views = View
  
  class << View
    def [](name)
      # find viewdoc by name
    end
  end

  class InvalidViewError < StandardError ; end
  
end


