module StrokeDB
  class ChunkStorage
    include ChainableStorage

    attr_accessor :authoritative_source

    def find(uuid)
      unless result = read(chunk_path(uuid)) 
        if authoritative_source
          result = authoritative_source.find(uuid) 
          save!(result,authoritative_source)
        end
      end
      result
    end

  end
end
