module StrokeDB
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
