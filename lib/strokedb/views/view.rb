module StrokeDB
  View = Meta.new do 
    
    DEFAULT_VIEW_OPTIONS = {
      "fixed_size_key" => nil,
      "heads"          => true,  # ???
      "inline"         => false,
      "on_duplicate_key" => :append  # :skip, :update
    }
    
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
      
      # Mode 1. startkey, count (skip)
      # Mode 2. startkey..endkey
      # Mode 3. key, count (skip) - prefix search
      
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
  
  Views = View
  
  class << View
    def [](name)
      # find viewdoc by name
    end
  end
  
end


