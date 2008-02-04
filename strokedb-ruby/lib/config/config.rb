module StrokeDB
  class UnknownStorageTypeError < Exception ; end
  class UnknownIndexTypeError < Exception ; end
  class UnknownStoreTypeError < Exception ; end
  class Config
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
    
    def add_store(key, type, storage = nil, options = {})
      store_class = constantize(:store,type)
      storage = @storages[storage||:default]
      raise "Missing storage for store #{key}" unless storage
      options[:index] ||= @indexes[:default]
      store_instance = store_class.get_new(storage, options)
      index = options[:index]
      index.document_store = store_instance if index
      @stores[key] = store_instance
    end
    
    private
    
    def constantize(name,type)
      type_fullname(name,type).constantize
    rescue 
      exception = "::StrokeDB::Unknown#{name.to_s.camelize}TypeError".constantize
      raise exception, "Unable to load #{name} type #{type}"
    end
    
    def type_fullname(type, name)
      "::StrokeDB::#{name.to_s.camelize}#{type.to_s.camelize}"
    end
    
  end
  
  class <<self
    def default_config
      Thread.current['StrokeDB.default_config']
    end
    def default_config=(config)
      Thread.current['StrokeDB.default_config'] = config
    end
  end
end
