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
        chunk = if @chunks_cache && (c = @chunks_cache[path])
          c
        else
          raw_chunk = @chunks_cache && @chunks_cache[path] || ActiveSupport::JSON.decode(IO.read(path))
          c = Chunk.from_raw(raw_chunk)
          @chunks_cache[path] = c if @chunks_cache
          c
        end
        prev_chunk.next_chunk = chunk if prev_chunk
        prev_chunk = chunk
        yield chunk
      end
    end

    def save!(chunk)
      FileUtils.mkdir_p @path
      File.open "#{@path}/#{chunk.uuid}", "w+" do |f|
        f.write chunk.to_raw.to_json
      end
      @chunks_cache[@path] = nil if @chunks_cache
    end
    
    def clear!
      FileUtils.rm_rf @path
    end
  end
end