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
      master_chunk = @chunk_storage.find('MASTER')
      return nil unless master_chunk  # no master chunk yet
      chunk_uuid = master_chunk.find_nearest(uuid, nil)
      return nil unless chunk_uuid # no chunks in master chunk yet
      chunk = @chunk_storage.find(chunk_uuid)
      return nil unless chunk
      if version
        chunk_node = chunk.find_node(uuid)
        val = nil
        until chunk_node.nil?
          break if ((val = chunk_node.value) && val['__version__'] == version)
          val = nil
          if chunk_node.is_a?(Skiplist::TailNode)
            chunk = chunk.next_chunk 
            break if chunk.nil? || chunk.uuid[0,uuid.length] != uuid
            chunk_node = chunk.first_node
          else
            chunk_node = chunk_node.next
          end
        end
        return nil unless val
        raw_doc = val
      else
        raw_doc = chunk.find(uuid)
      end
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
      next_lamport_timestamp
      doc.__lamport_timestamp__ = lamport_timestamp.to_s

      insert_with_cut(doc.uuid, doc, master_chunk)
      insert_with_cut("#{doc.uuid}.#{lamport_timestamp}", doc, master_chunk)

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
      after = options[:after_lamport_timestamp]
      include_versions = options[:include_versions]
      m.each do |node|
        chunk = @chunk_storage.find(node.value)
        next unless chunk
        next if after && chunk.lamport_timestamp <= after
        
        chunk.each do |node| 
          next if after && (node.value['__lamport_timestamp__'] <= after)
          if uuid_match = node.key.match(/#{UUID_RE}$/) || (include_versions && uuid_match = node.key.match(/#{UUID_RE}./) )
            yield Document.from_raw(self, uuid_match[1], node.value) 
          end
        end
      end
    end

    def lamport_timestamp
      @lamport_timestamp ||= LamportTimestamp.new(0).marshal_load(find_or_create_master_chunk.lamport_timestamp || LamportTimestamp.zero.to_s)
    end
    def next_lamport_timestamp
      @lamport_timestamp = lamport_timestamp.next
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
        chunk.lamport_timestamp = lamport_timestamp.to_s
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
