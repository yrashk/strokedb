module StrokeDB
  
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
    
    def save!(document)
      return store.save!(document) if document.versions.empty? || last_version(document.uuid) == document.previous_version
      raise MergeCondition.new(document)
    end
    
  end
  
end