module Stroke

  module Meta

    class <<self
      def new(*args,&block)
        mod = Module.new
        mod.module_eval do
          extend Meta
          @args = args
        end
        mod.module_eval(&block) if block_given?
        Object.const_set(extract_meta_name(*args),mod)
        mod
      end

      def document(store=nil)
        store ||= Stroke.default_store
        raise NoDefaultStoreError.new unless Stroke.default_store
        unless meta_doc = store.find(NIL_UUID)
          meta_doc = StrokeObject.new(store,:name => '::Stroke::Meta')
          meta_doc.instance_variable_set(:@uuid,NIL_UUID) # hack that ensures that meta meta is uniquely identified by nil uuid
          meta_doc.save!
        end
        meta_doc
      end

      private

      def extract_meta_name(*args)
        if args.first.is_a?(Hash) 
          args.first[:name]
        else
          args[1][:name]
        end
      end

    end

    def new(*args)
      doc = StrokeObject.new(*args)
      doc.extend(self)
      doc[:__meta__] = document(doc.store)
      doc
    end

    def inspect
      "<META #{name}>"
    end
    alias :to_s :inspect


    def document(store=nil)
      store ||= Stroke.default_store
      raise NoDefaultStoreError.new unless Stroke.default_store
      args = @args.clone
      args.unshift(store) if args.first.is_a?(Hash)
      args.last[:__meta__] = Meta.document(store)
      
      unless meta_doc = store.index_store ? store.index_store.find(:name => args[1][:name], 
                                                                  :__meta__ => Meta.document(store)).first : nil
        meta_doc = StrokeObject.new(*args)
        meta_doc.extend(Meta)
        meta_doc.save!
      else
        if (diff = StrokeObject.new(*args).diff(meta_doc)).different?
          diff.patch!(meta_doc)
          meta_doc.save!
        end
      end
      meta_doc
    end

  end

end

