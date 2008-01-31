module StrokeDB
  class Store
    # TODO: get rid of new_doc
    def new_doc(slots={})
      Document.new(self,slots)
    end

    private
    
    def document_class
      Document
    end
  end
end