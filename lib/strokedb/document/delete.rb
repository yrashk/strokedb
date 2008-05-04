module StrokeDB

  class DocumentDeletionError < StandardError
  end
  
  DeletedDocument = Meta.new do
    on_load do |doc|
      doc.make_immutable!
    end
    
    def undelete!
      deleted_version = versions.previous
      store.save_as_head!(deleted_version)
      store.find(uuid)
    end
  end
  
  class Document
    
    def delete!
      raise DocumentDeletionError, "can't delete non-head document" unless head?
      metas << DeletedDocument
      save!
      make_immutable!
    end
    
  end
end
