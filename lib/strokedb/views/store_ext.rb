module StrokeDB
  class Store
    
    
    # Tells a store to update a view on document save.
    #
    def register_view(v, metas = nil) #:nodoc:
      initialize_views_list
      if !metas || metas.empty?
        @registered_views[:rest] << v
      else
        metas.each do |meta_name|
          meta_name = meta_name.name if meta_name.is_a?(Meta)
          meta_name = meta_name.to_s
          @registered_views[meta_name] ||= [].to_set
          @registered_views[meta_name] << v
        end
      end
    end
    
    # This is called when new document version is created.
    #
    def update_views!(doc) #:nodoc:
      # Update generic views
      @registered_views[:rest].each do |view|
        view.update(doc)
      end
      doc.metas.each do |meta|
        views = @registered_views[meta['name']]
        if views
          views.each do |view|
            view.update(doc)
          end
        end
      end
    end
    
    # Lazy initialization (to avoid Store polluting)
    #
    alias :work_update_views! :update_views!
    def update_views!(doc)
      initialize_views_list
      class << self
        alias :update_views! :work_update_views!
      end
      update_views!(doc)
    end
    
    def initialize_views_list
      @registered_views ||= {
        :rest => [].to_set
        # meta_name => [...].to_set
      }
    end
    

    def view_storage(uuid)
      @view_storages ||= {}
      @view_storages[uuid] ||= FileViewStorage.new(:path => File.join(@options['path'],"views/#{uuid}"))
    end
  end
end
