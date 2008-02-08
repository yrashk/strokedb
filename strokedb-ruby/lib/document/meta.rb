module StrokeDB

  module Meta

    class <<self
      def new(*args,&block)
        mod = Module.new
        args = args.unshift(nil) if args.empty? || args.first.is_a?(Hash) 
        args << {} unless args.last.is_a?(Hash)
        mod.module_eval do
          extend Meta
          @args = args
        end
        mod.module_eval(&block) if block_given?
        if meta_name = extract_meta_name(*args)
          Object.const_set(meta_name,mod)
        end
        mod
      end

      def document(store=nil)
        store ||= StrokeDB.default_store
        raise NoDefaultStoreError.new unless StrokeDB.default_store
        unless meta_doc = store.find(NIL_UUID)
          meta_doc = Document.new(store,:name => Meta.name)
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
          args[1][:name] unless args.empty?
        end
      end

    end

    def on_meta_initialization(&block)
      @on_meta_initialization_block = block
    end

    def new(*args,&block)
      doc = Document.new(*args)
      doc.extend(self)
      doc[:__meta__] = document(doc.store)
      if @on_meta_initialization_block
        case @on_meta_initialization_block.arity
        when 2
          @on_meta_initialization_block.call(doc,block)
        when 1
          @on_meta_initialization_block.call(doc) 
        end
      end
      doc
    end

    def create!(*args,&block)
      new(*args,&block).save!
    end

    def inspect
      "<META #{name}>"
    end
    alias :to_s :inspect


    def document(store=nil)
      store ||= StrokeDB.default_store
      raise NoDefaultStoreError.new unless StrokeDB.default_store
      args = @args.clone
      args[0] = store
      args.last[:__meta__] = Meta.document(store)
      args.last[:name] ||= name
      unless meta_doc = (store.respond_to?(:index_store) && store.index_store) ? store.index_store.find(:name => args.last[:name], 
        :__meta__ => Meta.document(store)).first : nil
        meta_doc = Document.new(*args)
        meta_doc.extend(Meta)
        meta_doc.save!
      else
        if (new_doc = Document.new(*args)).version != meta_doc.version
          meta_doc.slotnames.each {|slotname| meta_doc.remove_slot!(slotname) }
          new_doc.slotnames.each {|slotname| meta_doc[slotname] = new_doc[slotname]}
          meta_doc.save!
        end
      end
      meta_doc
    end

  end

end

