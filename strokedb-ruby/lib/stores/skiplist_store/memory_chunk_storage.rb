module StrokeDB
  class MemoryChunkStorage < ChunkStorage
    attr_accessor :chunks_cache

    def initialize(*args)
      @chunks_cache = {}
    end
    
    def delete!(chunk_uuid)
      write(chunk_path(chunk_uuid), nil)
    end
    
    def clear!
      @chunks_cache.clear
    end
  
  private

    def perform_save!(chunk)
      write(chunk_path(chunk.uuid), chunk)
    end
    
    def read(path)
      @chunks_cache[path]
    end
    
    def write(path, chunk)
      @chunks_cache[path] = chunk
    end
    
    def chunk_path(uuid)
      uuid
    end
    
    
  end
end