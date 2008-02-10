module StrokeDB
  class SkiplistStore < Store
    include Enumerable
    attr_accessor :chunk_storage, :cut_level, :index_store
    attr_reader :uuid
    
    def initialize(chunk_storage, cut_level, index_store = nil)
      @chunk_storage = chunk_storage
      @cut_level = cut_level
      @index_store = index_store
      @uuid = Util.random_uuid
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
        doc = Document.from_raw(self,uuid,raw_doc.freeze)
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
      lts = lamport_timestamp + 1
      self.lamport_timestamp = doc.__lamport_timestamp__ = lts

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

    def each(options = {})
      return nil unless m = @chunk_storage.find('MASTER')  # no master chunk yet
      m.each do |node|
        chunk = @chunk_storage.find(node.value)
        chunk.each  do |node| 
          if node.key.match(/#{UUID_RE}$/) || (options[:include_versions] && node.key.match(/#{UUID_RE}.#{VERSION_RE}/) )
            yield Document.from_raw(self, node.key, node.value) 
          end
        end if chunk
      end
    end
    
    def lamport_timestamp
        find_or_create_master_chunk.lamport_timestamp || 0
    end
    def lamport_timestamp=(timestamp)
        find_or_create_master_chunk.lamport_timestamp = timestamp
    end

    private

    def insert_with_cut(uuid, doc, master_chunk)
      chunk_uuid = master_chunk.find_nearest(uuid)
      unless chunk_uuid && chunk = @chunk_storage.find(chunk_uuid)
        chunk = Chunk.new(@cut_level)
      end
      a, b = chunk.insert(uuid, doc.to_raw)
      [a,b].compact.each do |chunk|
        chunk.store_uuid = self.uuid
        chunk.lamport_timestamp = lamport_timestamp
      end
      # if split
      if b
        # rename chunk if the first chunk inconsistency detected 
        if a.uuid != a.first_uuid
          old_uuid = a.uuid
          a.uuid = a.first_uuid
          @chunk_storage.save!(a)
          master_chunk.insert(a.uuid, a.uuid)
          # remove old chunk
          @chunk_storage.delete!(old_uuid)
          master_chunk.delete(old_uuid)
        else
          @chunk_storage.save!(a)
          master_chunk.insert(a.uuid, a.uuid)
        end
        @chunk_storage.save!(b)
        master_chunk.insert(b.uuid, b.uuid)
      else
        @chunk_storage.save!(a)
        master_chunk.insert(a.uuid, a.uuid)
      end
    end

    def find_or_create_master_chunk
      if master_chunk = @chunk_storage.find('MASTER')
        return master_chunk 
      end
      master_chunk = Chunk.new(999)
      master_chunk.uuid = 'MASTER'
      master_chunk.store_uuid = @uuid
      @chunk_storage.save!(master_chunk)
      master_chunk
    end

  end
end
