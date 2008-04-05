module StrokeDB

  class DocumentDeletionError < StandardError
  end
  
  DeletedDocument = Meta.new(:uuid => 'e5e0ef20-e10f-4269-bff3-3040a90e194e') do
    on_load do |doc|
      doc.make_immutable!
    end
    
    after_save do |doc|
      doc.make_immutable!
    end
    
    def undelete!
      deleted_version = versions.previous
      store.save_as_head!(deleted_version)
      self.class.find(uuid)
    end
  end
  
  class Document
    
    def delete!
      raise DocumentDeletionError, "can't delete non-head document" unless head?
      metas << DeletedDocument
      save!
    end
    
  end
end