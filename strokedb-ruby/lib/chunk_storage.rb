module StrokeDB
  class ChunkStorage

    def initialize(*args)
    end

    def add_replica!(storage)
      @replicas ||= {}
      @replicas[storage] = []
    end
    
    def remove_replica!(storage)
      @replicas.delete(storage)
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


    def save!(chunk)
      perform_save!(chunk)
      (@replicas||{}).each_pair do |storage,savings|
        savings << chunk
      end
    end


  end
end