module StrokeDB
  module ChainableStorage
    def add_chained_storage!(storage)
      @chained_storages ||= {}
      @chained_storages[storage] = []
      class <<self
        alias :save! :save_with_chained_storages!
      end
      storage.add_chained_storage!(self) unless storage.has_chained_storage?(self)
    end

    def remove_chained_storage!(storage)
      @chained_storages.delete(storage)
      storage.remove_chained_storage!(self) if storage.has_chained_storage?(self)
      if @chained_storages.keys.empty?
        class <<self
          alias :save! :save_without_chained_storages!
        end
      end
    end

    def has_chained_storage?(storage)
      @chained_storages.nil? ? false : !!@chained_storages[storage]
    end

    def sync_chained_storages!
      @chained_storages.each_pair do |storage, savings|
        savings.each {|saving| storage.save!(saving, self)}
      end
      @chained_storages = {}
    end
    
    def sync_chained_storage!(storage)
      (@chained_storages[storage]||[]).each do |saving|
        storage.save!(saving,self)
      end
      @chained_storages[storage] = []
    end

    def save_without_chained_storages!(chunk)
      perform_save!(chunk)
    end

    def save_with_chained_storages!(chunk,source=nil)
      perform_save!(chunk)
      (@chained_storages||{}).each_pair do |storage,savings|
          savings << chunk unless  storage == chunk || savings.include?(chunk)
      end
    end

    alias :save! :save_without_chained_storages!
  end
end
