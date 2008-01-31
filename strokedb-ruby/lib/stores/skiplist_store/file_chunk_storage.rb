module StrokeDB
  class FileChunkStorage < ChunkStorage
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def clear!
      FileUtils.rm_rf @path
    end
    
  private
    
    def perform_save!(chunk)
      FileUtils.mkdir_p @path
      write(chunk_path(chunk.uuid), chunk)
    end
    
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
    
  end
end