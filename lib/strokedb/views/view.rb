module StrokeDB
  View = Meta.new do 
    
    DEFAULT_VIEW_OPTIONS = {
      # Declare the size for a key to use optimized index file
      # (size in bytes).
      "fixed_size_key"   => nil,
      
      # By default, view index stores dpointers to the actual data
      # if you want need to store some actual data you may set this to
      # true or a particular size (in bytes).
      # Note: optimized storage is used when both keys and values 
      # have the fixed length. I.e. "inline" is false or an integer and 
      # "fixed_size_key" is an integer.
      "inline"           => false,  # Integer 
      
      # strategy determines whether to index HEADs or particular versions
      # When :heads is used, previous versions are removed from the index.
      "strategy"         => :heads, # :versions
      
      # what to do when the key is duplicated: add to list (append/prepend),
      # overwrite or don't do anything (:skip).
      "on_duplicate_key" => :append # :prepend, :skip, :overwrite
    }
    
    on_initialization do |viewdoc|
      unless viewdoc["name"]
        raise ArgumentError, "View name must be specified!"
      end
      
      # pass viewdoc into initialization block:
      # my_view = View.new(){ |view| ... }
      if initialization_block = viewdoc.instance_variable_get(:@initialization_block)
        initialization_block.call(viewdoc)
      end
    end
    
    DEFAULT_FIND_OPTIONS = {
      :startkey   => nil,
      :endkey     => nil,
      :count      => nil,  :limit => nil,   # aliases
      :descending => false,
      :skip       => nil,  :offset => nil,  # aliases
      :key        => nil,   # prefix search
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
      
      startkey   = options[:startkey]
      endkey     = options[:endkey]
      key        = options[:key]
      count      = options[:count]   || options[:limit]
      skip       = options[:skip]    || options[:offset]
      reverse    = options[:reverse] || options[:descending]
      with_keys  = options[:with_keys]
      
      ugly_find(startkey, endkey, key, count, skip, reverse, with_keys)
    end
    
    # Ugly find accepts fixed set of arguments and works a bit faster, 
    # than a regular #find(options = {}) [probably insignificantly faster, TODO: check this]
    # Some arguments can be nils.
    # 
    def ugly_find(startkey, endkey, key, count, skip, reverse, with_keys)
      
      # Mode 1. startkey, count (skip)
      # Mode 2. startkey..endkey
      # Mode 3. key, count (skip) - prefix search
      
      if key 
        endkey = startkey = key
      end
      
      array = storage.find(encode_key(startkey), 
                           endkey && encode_key(endkey), 
                           count, 
                           skip, 
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
    
    
    # This is used by the storage to update index
    # with a new version of document
    def insert(doc) #:nodoc:
      pairs = map(doc)
      
      # TODO: insert pairs into the storage
      
      
      
    end
    
    
    # These are defaults (to by overriden in View.new{|v| ... })
    
    def map(doc)
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
      # Or find/create a blob and emit pointer to it.
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


