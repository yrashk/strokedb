module StrokeDB
  class Store
    def new_doc(slots={})
      Document.new(self,slots)
    end
    
    private
    
    def document_class
      Document
    end
  end
end