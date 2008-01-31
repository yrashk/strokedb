module StrokeDB
  module ReplicableStorage
    def add_replica!(storage)
      @replicas ||= {}
      @replicas[storage] = []
      class <<self
        alias :save! :save_with_replicas!
      end
    end

    def remove_replica!(storage)
      @replicas.delete(storage)
      if @replicas.keys.empty?
        class <<self
          alias :save! :save_without_replicas!
        end
      end
    end

    def replicate!(storage=nil)
      if storage.nil?
        @replicas.each_pair do |storage, savings|
          savings.each {|saving| storage.save!(saving)}
        end
        @replicas = {}
      else
        (@replicas[storage]||[]).each do |saving|
          storage.save!(saving)
        end
        @replicas[storage] = []
      end
    end

    def save_without_replicas!(chunk)
      perform_save!(chunk)
    end

    def save_with_replicas!(chunk)
      perform_save!(chunk)
      (@replicas||{}).each_pair do |storage,savings|
        savings << chunk unless savings.include?(chunk)
      end
    end

    alias :save! :save_without_replicas!
  end
end
