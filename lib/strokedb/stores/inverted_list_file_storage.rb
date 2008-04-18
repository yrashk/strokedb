module StrokeDB
  class InvertedListFileStorage
    # TODO: 
    # include ChainableStorage

    attr_accessor :path

    def initialize(opts={})
      opts = opts.stringify_keys 
      @path = opts['path']
    end

    def find_list
      read(file_path)
    end
    
    def clear!
      FileUtils.rm_rf @path
    end
    
    def save!(list)
      FileUtils.mkdir_p @path
      write(file_path, list)
    end
    
  private

    def read(path)
      return InvertedList.new unless File.exist?(path)
      raw_list = StrokeDB.deserialize(IO.read(path))
      list = InvertedList.new
      # TODO: Optimize!
      raw_list.each do |k, vs|
        vs.each do |v|
          list.insert_attribute(k, v)
        end
      end
      list
    end
    
    def write(path, list)
      raw_list = {}
      # TODO: Optimize!
      list.each do |n|
        raw_list[n.key] = n.values
      end
      File.open path, "w+" do |f|
        f.write StrokeDB.serialize(raw_list)
      end
    end
  
    def file_path
      "#{@path}/INVERTED_INDEX"
    end
  end
  
  
  
  class InvertedListIndex
    attr_accessor :storage, :document_store
    def initialize(storage)
      @storage = storage
      @list = nil
    end
    
    def find_uuids(*args)
      list.find(*args)
    end
    
    def find(*args)
      find_uuids(*args).map do |uuid|
        @document_store.find(uuid)
      end
    end
    
    def insert(doc)
      slots = indexable_slots_for_doc(doc)
      q = PointQuery.new(slots)
      list.insert(q.slots, doc.uuid)
    end
     
    def delete(doc)
      slots = indexable_slots_for_doc(doc)
      q = PointQuery.new(slots)
      list.delete(q.slots, doc.uuid)
    end
    
    def save!
      @storage.save!(list)
    end
  
  private
    
    def indexable_slots_for_doc(doc)
      raw_slots = doc.to_raw
      nkeys = doc.meta['non_indexable_slots']
      nkeys.each{|nk| raw_slots.delete(nk) } if nkeys
      raw_slots
    end
    
    def list
      @list ||= @storage.find_list
    end
    
  end
end
