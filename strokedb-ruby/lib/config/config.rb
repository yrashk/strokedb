require 'assistance/inflector'

module StrokeDB
  class UnknownStorageTypeError < Exception ; end
  class UnknownIndexTypeError < Exception ; end
  class UnknownStoreTypeError < Exception ; end
  class Config
    attr_reader :storages, :indexes, :stores
    def initialize(default = false)
      @storages = {}
      @indexes = {}
      @stores = {}
      ::StrokeDB.default_config = self if default
    end
    
    def [](name)
      @storages[name] || @indexes[name] || nil
    end
    
    def add_storage(key, type, *args)
      storage_type = full_storage_type(type)
      begin
        storage_class = Inflector.constantize storage_type
      rescue => e
        raise UnknownStorageTypeError, "Unable to load storage type #{storage_type}"
      end
      storage_instance = storage_class.new(*args)
      @storages[key] = storage_instance
      return @storages[key]
    end
    
    def chain_storages(a, b, options = {})
      sa, sb = @storages[a], @storages[b]
      raise "Missing storage #{a}" unless sa
      raise "Missing storage #{b}" unless sb
      sa.add_chained_storage!(sb)
      if xopt = options[:authoritative]
        sa.authoritative_source = sb if xopt == b
        sb.authoritative_source = sa if xopt == a
      end
      return sa, sb
    end
    alias :chain :chain_storages
    
    def add_index(key, type, storage_key, store_key = nil)
      index_type = full_index_type(type)
      begin
        index_class = Inflector.constantize index_type
      rescue => e
        raise UnknownIndexTypeError, "Unable to load index type #{index_type}"
      end
      index_instance = index_class.new(@storages[storage_key])
      index_instance.document_store = @stores[store_key] if store_key
      @indexes[key] = index_instance
      return @indexes[key]
    end
    
    def add_store(key, type, storage = nil, options = {})
      store_type = full_store_type(type)
      begin
        store_class = Inflector.constantize store_type
      rescue => e
        raise UnknownStoreTypeError, "Unable to load store type #{store_type}"
      end
      storage ||= :default
      storage = @storages[storage]
      raise "Missing storage for store #{key}" unless storage
      options[:index] ||= @indexes[:default]
      store_instance = store_class.get_new(storage, options)
      @stores[key] = store_instance
      options[:index].document_store = store_instance if options[:index]
      return @stores[key]
    end
    
    private
    
    def full_storage_type(type)
      'StrokeDB::' + Inflector.classify(type.to_s) + 'Storage'
    end
    
    def full_index_type(type)
      'StrokeDB::' + Inflector.classify(type.to_s) + 'Index'
    end
    
    def full_store_type(type)
      'StrokeDB::' + Inflector.classify(type.to_s) + 'Store'
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
