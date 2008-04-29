module StrokeDB
  class Store

    # Tells store to update a view on document save.
    #
    def register_view(v) #:nodoc:
      @registered_views ||= [].to_set
      @registered_views << v
    end
    
    # This is called when new document version is created.
    #
    def update_views!(doc) #:nodoc:
      (@registered_views || []).each do |view|
        view.update(doc)
      end
    end
  end
end
