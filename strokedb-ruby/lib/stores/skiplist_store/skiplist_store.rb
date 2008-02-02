module StrokeDB
  class SkiplistStore < Store
    attr_accessor :chunk_storage, :cut_level, :index_store

    def initialize(chunk_storage, cut_level, index_store = nil)
      @chunk_storage = chunk_storage
      @cut_level = cut_level
      @index_store = index_store
    end
    
    def self.get_new(storage, options = {})
      raise "Missing cut_level" unless options[:cut_level]
      new(storage, options[:cut_level], options[:index])
    end
    
    def find(uuid, version=nil)
      uuid_version = uuid + (version ? ".#{version}" : "") 
      master_chunk = @chunk_storage.find('MASTER')
      return nil unless master_chunk  # no master chunk yet
      chunk_uuid = master_chunk.find_nearest(uuid_version, nil)
      return nil unless chunk_uuid # no chunks in master chunk yet
      chunk = @chunk_storage.find(chunk_uuid)
      raw_doc = chunk.find(uuid_version)
      if raw_doc
        doc = document_class.from_raw(self,uuid,raw_doc.freeze)
        doc.extend(VersionedDocument) if version
        return doc
      end
      nil
    end

    def exists?(uuid)
      !!find(uuid)
    end

    def last_version(uuid)
      raw_doc = find(uuid)
      return raw_doc.version if raw_doc
      nil
    end

    def save!(doc)
      master_chunk = find_or_create_master_chunk

      insert_with_cut(doc.uuid,         doc, master_chunk)
      insert_with_cut(doc.uuid_version, doc, master_chunk)
      
      @chunk_storage.save!(master_chunk)
      
      # Update index
      if @index_store
        if doc.previous_version
          pdoc = doc.versions[doc.previous_version]
          @index_store.delete(pdoc)
        end
        @index_store.insert(doc)
        @index_store.save!
      end
    end  
  
    def full_dump
      puts "Full storage dump:"
      m = @chunk_storage.find('MASTER')
      puts "No master!" unless m
      m.each do |node|
        puts "[chunk: #{node.key}]"
        chunk = @chunk_storage.find(node.value)
        if chunk
          chunk.each do |node|
            puts "    [doc: #{node.key}] => {uuid: #{node.value['__uuid__']}, version: #{node.value['__version__']}, previous_version: #{node.value['__previous_version__']}"
          end
        else
          puts "    nil! (but in MASTER somehow?...)"
        end
      end
    end
  
  private
    
    def insert_with_cut(uuid, doc, master_chunk)
      chunk_uuid = master_chunk.find_nearest(uuid)
      unless chunk_uuid && chunk = @chunk_storage.find(chunk_uuid)
        chunk = Chunk.new(@cut_level)
      end
      a, b = chunk.insert(uuid, doc.to_raw)
      @chunk_storage.save!(a)
      master_chunk.insert(a.uuid, a.uuid)
      if b
        @chunk_storage.save!(b)
        master_chunk.insert(b.uuid, b.uuid)
      end
    end
  
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
