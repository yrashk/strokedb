module StrokeDB
  class MemoryChunkStorage
    attr_accessor :chunks_cache

    def initialize
      @chunks_cache = {}
    end
      
    def find(uuid)
      read(chunk_path(uuid))
    end

    def save!(chunk)
      write(chunk_path(chunk.uuid), chunk)
    end
    
    def clear!
      @chunks_cache.clear
    end
    
  
  private
    
    def chunk_path(uuid)
      uuid
    end
    
    def read(path)
      @chunks_cache[path]
    end
    
    def write(path, chunk)
      @chunks_cache[path] = chunk
    end
    
  end
end