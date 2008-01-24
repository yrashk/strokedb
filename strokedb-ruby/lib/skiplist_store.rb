module StrokeDB
  class SkiplistStore < Store
    attr_accessor :chunk_storage, :cut_level

    def initialize(chunk_storage, cut_level)
      @chunk_storage = chunk_storage
      @cut_level = cut_level
    end
    
    def find(uuid, version=nil)
      master_chunk = @chunk_storage.find('MASTER')
      return nil unless master_chunk  # no master chunk yet
      chunk_uuid = master_chunk.find_nearest(uuid, nil)
      return nil unless chunk_uuid # no chunks in master chunk yet
      chunk = @chunk_storage.find(chunk_uuid)
      raw_doc = chunk.find(uuid + (version ? ".#{version}" : "") )
      return Document.from_raw(self,raw_doc) if raw_doc
      nil
    end

    def exists?(uuid)
      # TODO: master chunk scanning
      !!find(uuid)
    end

    def last_version(uuid)
      @chunk_storage.each do |chunk|
        raw_doc = chunk.find(uuid)
        return raw_doc['__version__'] if raw_doc
      end
      nil
    end

    def save!(doc)
      master_chunk = find_or_create_master_chunk
      is_cur_chunk_new = false
      chunk_uuid = master_chunk.find_nearest(doc.uuid)
      unless chunk_uuid && chunk = @chunk_storage.find(chunk_uuid)
        chunk = Chunk.new(@cut_level) 
        is_cur_chunk_new = true
      #  puts "Very first new chunk! chunk_uuid = #{chunk_uuid}"
      end
      
      cur_chunk, new_chunk = chunk.insert(doc.uuid, doc.to_raw)
      [cur_chunk, new_chunk].compact.each do |chunk|
        @chunk_storage.save!(chunk)
      end
            
      master_chunk.insert(cur_chunk.uuid, cur_chunk.uuid) if is_cur_chunk_new
      master_chunk.insert(new_chunk.uuid, new_chunk.uuid) if new_chunk
      
      cur_chunk, new_chunk = (new_chunk||cur_chunk).insert("#{doc.uuid}.#{doc.version}", doc.to_raw)
      [cur_chunk, new_chunk].compact.each do |chunk|
        @chunk_storage.save!(chunk)
      end
      master_chunk.insert(new_chunk.uuid, new_chunk.uuid) if new_chunk

      @chunk_storage.save!(master_chunk)
    end
  
  private
  
    def find_or_create_master_chunk
      if master_chunk = @chunk_storage.find('MASTER')
        return master_chunk 
      end
      master_chunk = Chunk.new(999)
      master_chunk.uuid = 'MASTER'
      @chunk_storage.save!(master_chunk)
      master_chunk
    end
    
  end
end
