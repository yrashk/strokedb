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
        class << self
          alias :save! :save_without_chained_storages!
        end
      end
    end

    def has_chained_storage?(storage)
      @chained_storages.nil? ? false : !!@chained_storages[storage]
    end

    def sync_chained_storages!(origin=nil)
      return unless @chained_storages.is_a?(Hash)
      @chained_storages.each_pair do |storage, savings|
        next if storage == origin
        savings.each {|saving| storage.save!(saving[0], saving[1], self)}
        storage.sync_chained_storages!(self)
        @chained_storages[storage] = [] 
      end
    end
    
    def sync_chained_storage!(storage)
      return unless @chained_storages.is_a?(Hash)
      (@chained_storages[storage]||[]).each do |saving|
        storage.save!(saving[0],saving[1],self)
      end
      @chained_storages[storage] = []
    end

    def save_without_chained_storages!(document, timestamp, source=nil)
      perform_save!(document, timestamp)
    end

    def save_with_chained_storages!(document, timestamp, source=nil)
      perform_save!(document, timestamp)
      (@chained_storages||{}).each_pair do |storage,savings|
          savings << [document,timestamp] unless  storage == document || savings.include?([document,timestamp])
      end
    end

    alias :save! :save_without_chained_storages!
  end
end
