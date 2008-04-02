module StrokeDB
  class UnknownStorageTypeError < Exception ; end
  class UnknownIndexTypeError < Exception ; end
  class UnknownStoreTypeError < Exception ; end
  class Config
    
    
    class << self
    
      def load(filename,default = false)
        build(JSON.parse(IO.read(filename)).merge(:default => default))
      end
      
      def build(opts={})
        opts = opts.stringify_keys
        config = new(opts['default'])
        storages = opts['storages'] || [:memory, :file]
        initialized_storages = []
        storages.each do |storage|
          initialized_storages << config.add_storage(storage,storage,:path => File.join(opts['base_path']||'./',storage.to_s))
        end
        config.chain(*storages)  if storages.size >= 2
        initialized_storages[0,initialized_storages.size-1].each_with_index do |storage,index|
          storage.authoritative_source = initialized_storages[index+1]
        end
        index_storages = opts['index_storages'] || [:inverted_list_file]
        index_storages.each do |index|
          config.add_storage(index,index,:path => File.join(opts['base_path']||'./',index.to_s))
        end
        index = opts['index'] || :inverted_list
        config.add_index(:default,index,index_storages.first)
        unless store = opts['store'] 
          config.add_store(:default,nil, {:storage => storages.first, :path => opts['base_path']}.merge(opts['store_options']||{})) # FIXME: nil isn't nice
        else 
          config.add_store(:default,store,{:storage => storages.first}.merge(opts['store_options']||{}))
        end
        config.build_config = opts.except('default')
        FileUtils.mkdir_p opts['base_path']||'./'
        File.open(File.join(opts['base_path']||'./','config'),"w+") do |f|
          f.write config.build_config.to_json
        end
        config
      end
      
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
      storage_class = constantize(:storage,type)
      storage_instance = storage_class.new(*args)
      @storages[key] = storage_instance
    end
    
    def chain_storages(*args)
      raise "Not enough storages to chain storages" unless args.size >= 2
      ss = args.map{|x| @storages[x] || raise("Missing storage #{x}")}
      (0..ss.length-2).each do |idx|
        ss[idx].add_chained_storage!(ss[idx+1])
      end
    end
    alias :chain :chain_storages
    
    def add_index(key, type, storage_key, store_key = nil)
      index_class = constantize(:index,type)
      index_instance = index_class.new(@storages[storage_key])
      index_instance.document_store = @stores[store_key] if store_key
      @indexes[key] = index_instance
    end
    
    def add_store(key, type, options = {})
      store_class = constantize(:store,type)
      storage = options[:storage] = @storages[options[:storage]||:default]
      raise "Missing storage for store #{key}" unless storage
      options[:index] ||= @indexes[options[:index]||:default]
      store_instance = store_class.new(options)
      index = options[:index]
      index.document_store = store_instance if index
      @stores[key] = store_instance
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
  
  class <<self
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
