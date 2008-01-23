module StrokeDB
  class FileChunkStorage
    attr_accessor :path
    def initialize(path)
      @path = path
    end
    
    def each
      # TODO: master chunk scanning
      @paths = Dir["#{@path}/**"].sort # FIXME: File.join? Dir.glob special params?
      prev_chunk = nil
      paths.each do |path|
        raw_chunk = ActiveSupport::JSON.decode(IO.read(path))
        chunk = Chunk.from_raw(raw_chunk)
        prev_chunk.next_chunk = chunk if prev_chunk
        prev_chunk = chunk
        yield chunk
      end
    end

    def save!(chunk)
      File.open "#{@path}/#{chunk.uuid}", "w+" do |f|
        f.write chunk.to_raw.to_json
      end
    end
    
  end
end