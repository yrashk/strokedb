module StrokeDB

  class MergeStrategy
    
  end
  
  class MergeCondition < Exception
    attr_reader :document
    def initialize(document)
      @document = document
    end
  end
  
  class MergingStore
    attr_reader :store
    def initialize(store)
      @store = store
    end
    
    def exists?(uuid)
      @store.exists?(uuid)
    end
    
    def last_version(uuid)
      @store.last_version(uuid)
    end
    
    def find(uuid,version=nil)
      @store.find(uuid,version)
    end
    
    def save!(document)
      _last_version = find(document.uuid)
      return store.save!(document) if document.versions.empty? || _last_version.version == document.previous_version
      return store.save!(document.meta[:__merge_strategy__].camelize.constantize.merge!(document,_last_version)) if document.meta && document.meta[:__merge_strategy__]
      raise MergeCondition.new(document)
    end
    
    
  end
  
end