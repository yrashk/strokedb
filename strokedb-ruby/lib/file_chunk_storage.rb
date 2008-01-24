module StrokeDB
  class FileChunkStorage
    attr_accessor :path, :chunks_cache
    def initialize(path)
      @path = path
    end
    
    def each
      # TODO: master chunk scanning
      @paths = Dir["#{@path}/**"].sort # FIXME: File.join? Dir.glob special params?
      prev_chunk = nil
      @paths.each do |path|
        chunk = read(path)
        prev_chunk.next_chunk = chunk if prev_chunk
        prev_chunk = chunk
        yield chunk
      end
    end
    
    def find(uuid)
      read(chunk_path(uuid))
    end

    def save!(chunk)
      FileUtils.mkdir_p @path
      write(chunk_path(chunk.uuid), chunk)
    end
    
    def clear!
      @chunks_cache.clear if @chunks_cache
      FileUtils.rm_rf @path
    end
    
  private
    
    def read(path)
      return nil unless File.exist?(path)
      raw_chunk = ActiveSupport::JSON.decode(IO.read(path))
      Chunk.from_raw(raw_chunk)
    end
    
    def write(path, chunk)
      File.open path, "w+" do |f|
        f.write chunk.to_raw.to_json
      end
    end
    
    def chunk_path(uuid)
      "#{@path}/#{uuid}"
    end
    
    # Optimizations
    
    def read_with_cache(path)
      unless @chunks_cache && (c = @chunks_cache[path])
        c = @chunks_cache && @chunks_cache[path] || read_without_cache(path)
        @chunks_cache[path] = c if @chunks_cache
      end
      c
    end
    
    # use storage.flush! to dump changes to disk and empty cache
    def write_with_cache(path, chunk)
      if @chunks_cache
        @chunks_cache[path] = chunk
      else
        write_without_cache(path, chunk)
      end
    end
    
    def flush!
      @chunks_cache.each do |path, chunk|
        write_without_cache(path, chunk) 
      end
      @chunks_cache.clear
    end
    public :flush!
    alias_method_chain :read,  :cache
    alias_method_chain :write, :cache
    
  end
end