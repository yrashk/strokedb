module StrokeDB
  
  class Transaction
    
    attr_reader :uuid
    
    def initialize(options = {})
      @options = options.stringify_keys
      @uuid = Util.random_uuid
      storage.add_chained_storage!(store.storage)
    end
    
    def storage
      @options['storage'] ||= setup_storage
    end
    
    def store
      @options['store']
    end
    
    def inspect
      "#<Transaction #{@uuid}>"
    end
    
    def find(uuid, version=nil, opts = {})
      storage.find(uuid,version,opts.merge(:store => self))
    end
    
    def head_version(uuid)
      storage.head_version(uuid,{ :store => self })
    end
    
    def save!(doc)
      @timestamp = @timestamp.next
      storage.save!(doc,@timestamp)
    end
    
    def execute
      raise ArgumentError, "no block provided" unless block_given?

      Thread.current[:strokedb_transactions] ||= []
      Thread.current[:strokedb_transactions].push self
      
      @timestamp = LTS.new(store.timestamp.counter,uuid)

      begin
        result = yield(self)
      rescue 
        throw $!
      ensure
        Thread.current[:strokedb_transactions].pop
      end
      
      
      result
    end
    
    def commit!
      storage.sync_chained_storage!(store.storage)
      true
    end
    
    def rollback!
      @options['storage'] = setup_storage
      true
    end
    
    private
    
    def setup_storage
      storage = MemoryStorage.new
      storage.authoritative_source = store.storage
      storage
    end
    
  end
  
end