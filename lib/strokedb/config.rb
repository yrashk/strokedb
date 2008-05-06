module StrokeDB
  # errors raised in the process of configuration

  class UnknownStorageTypeError < Exception; end
  class UnknownIndexTypeError   < Exception; end
  class UnknownStoreTypeError   < Exception; end

  class Config
    #
    # Load config from file, probably making it the default one
    #
    def Config.load(filename, default = false)
      build(JSON.parse(IO.read(filename)).merge(:default => default))
    end

    #
    # Build the config from given options.
    #
    # Supported options are:
    #
    #   :default - if set to true, config becomes the default one.
    #   :storages - must be an array of storage types.
    #               Appropriate storages will be initialized and chained
    #               together. Defaults to [:memory_chunk, :file_chunk]
    #   :index_storages - index storages. Defaults to [:inverted_list_file].
    #   :index - index type. Defaults to :inverted_list. 
    #   :base_path - if set, specifies the path for storages. Otherwise,
    #                current directory is used.
    #   :store - store type to use. Defaults to :skiplist.
    #   :store_options - options passed to the created store

    def Config.build(opts={})
      opts = opts.stringify_keys
      
      config = new(opts['default'])
      storages = opts['storages'] || [:memory, :file]

      base_path = opts['base_path'] || './'

      add_storage = lambda do |name| 
        config.add_storage(name, name, :path => File.join(base_path, name.to_s))
      end

      ### setup document storages ###
      
      initialized_storages = storages.map(&add_storage)       
      config.chain(*storages) if storages.size >= 2

      initialized_storages.each_consecutive_pair do |cur, nxt|
        # next storage is authoritative for each storage
        cur.authoritative_source = nxt
      end
      
      ### setup index storages and indexes ###

      index_storages = opts['index_storages'] || [:inverted_list_file]
      index_storages.each(&add_storage)

      config.add_index(:default, opts['index'] || :inverted_list, index_storages.first)

      config.add_store(:default, opts['store'], # FIXME: nil here is a Bad Thing (tm) 
                       { :storage => storages.first, :path => base_path }.merge(opts['store_options'] || {}))

      ### save config ###

      config.build_config = opts.except('default')
      
      FileUtils.mkdir_p base_path
      File.open(File.join(base_path,'config'), "w+") do |file|
        file.write config.build_config.to_json
      end

      config
    end
      
    attr_accessor :build_config
    attr_reader :storages, :indexes, :stores

    def initialize(default = false)
      @storages, @indexes, @stores = {}, {}, {}

      ::StrokeDB.default_config = self if default
    end
 
    def [](name)
      @storages[name] || @indexes[name] || nil
    end
    
    def add_storage(key, type, *args)
      @storages[key] = constantize(:storage, type).new(*args)
    end
    
    def chain_storages(*args)
      raise ArgumentError, "Not enough storages to chain storages" unless args.size >= 2

      args.map {|x| @storages[x] || raise("Missing storage #{x}") }.each_consecutive_pair do |cur, nxt|
        cur.add_chained_storage! nxt
      end
    end
    
    alias :chain :chain_storages
    
    def add_index(key, type, storage_key, store_key = nil)
      @indexes[key] = constantize(:index, type).new(@storages[storage_key])
      @indexes[key].document_store = @stores[store_key] if store_key
    end
    
    def add_store(key, type, options = {})
      
      options[:storage] = @storages[options[:storage] || :default]
      raise "Missing storage for store #{key}" unless options[:storage]
      
      options[:index] ||= @indexes[options[:index] || :default]
      
      store_instance = constantize(:store, type).new(options)
      
      if options[:index]
        options[:index].document_store = store_instance
      end

      @stores[key] = store_instance
    end
    
    def inspect
      "#<StrokeDB::Config:0x#{object_id.to_s(16)}>"
    end
    
    private
    
    def constantize(name,type)
      StrokeDB.const_get type_fullname(name,type)
    rescue 
      exception = StrokeDB.const_get("Unknown#{name.to_s.camelize}TypeError")
      raise exception, "Unable to load #{name} type #{type}"
    end
    
    def type_fullname(type, name)
      "#{name.to_s.camelize}#{type.to_s.camelize}"
    end
  end
  
  class << self
    def use_perthread_default_config!
      class << self
        def default_config
          Thread.current['StrokeDB.default_config']
        end
        def default_config=(config)
          Thread.current['StrokeDB.default_config'] = config
        end
      end
    end
    def use_global_default_config!
      class << self
        def default_config
          $strokedb_default_config
        end
        def default_config=(config)
          $strokedb_default_config = config
        end
      end
    end
  end
end

StrokeDB.use_perthread_default_config!
