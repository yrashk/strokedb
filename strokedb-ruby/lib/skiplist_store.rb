module StrokeDB
  class SkiplistStore < Store
    attr_accessor :chunk_storage, :cut_level

    def initialize(chunk_storage, cut_level)
      @chunk_storage = chunk_storage
      @cut_level = cut_level
    end
    
    def find(uuid, version=nil)
      # TODO: master chunk scanning
      @chunk_storage.each do |chunk|
        raw_doc = chunk.find(uuid)
        return Document.from_raw(raw_doc) if raw_doc
      end
      nil
    end

    def exists?(uuid)
      # TODO: master chunk scanning
      !!find(uuid)
    end

    def last_version(uuid)
      # TODO: dunno
    end

    def save!(doc)
      mychunk = nil
      # determine a chunk where to insert
      @chunk_storage.each do |chunk|
        # later chunk
        if doc.uuid < chunk.uuid
          if mychunk
            break
          else
            # actually, the first chunk, so use it:
            # will insert in the head 
            mychunk = chunk 
            break
          end
        else # >=
          mychunk = chunk
        end
      end
      mychunk ||= Chunk.new(@cut_level)
      # insert to mychunk
      cur_chunk, new_chunk = mychunk.insert(doc.uuid, doc.to_raw)
      [cur_chunk, new_chunk].compact.each do |chunk|
        @chunk_storage.save!(chunk)
      end
    end
  end
end
