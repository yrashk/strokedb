module StrokeDB
  
  class Transaction
    
    def initialize(options = {})
      @options = options.stringify_keys
      storage.add_chained_storage!(store.storage)
    end
    
    def storage
      @options['storage'] ||= setup_storage
    end
    
    def store
      @options['store']
    end
    
    def inspect
      "#<Transaction #{object_id}>"
    end
    
    def find(uuid, version=nil, opts = {})
      storage.find(uuid,version,opts.merge(:store => self))
    end
    
    def save!(doc)
      storage.save!(doc,@timestamp)
    end
    
    def execute
      raise ArgumentError, "no block provided" unless block_given?

      Thread.current[:strokedb_transactions] ||= []
      Thread.current[:strokedb_transactions].push self
      
      @timestamp = store.timestamp
      
      result = yield(self)
      
      Thread.current[:strokedb_transactions].pop
      
      ObjectSpace.each_object(Document) do |doc|
        doc.instance_variable_set(:@store, store) if doc.store == self || doc.store.nil?
      end
      result
    end
    
    def commit!
      storage.sync_chained_storage!(store.storage)
    end
    
    def rollback!
      @options['storage'] = setup_storage
    end
    
    private
    
    def setup_storage
      storage = MemoryStorage.new
      storage.authoritative_source = store.storage
      storage
    end
    
  end
  
end