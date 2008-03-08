module StrokeDB

  module Meta

    class << self
      def new(*args,&block)
        mod = Module.new
        args = args.unshift(nil) if args.empty? || args.first.is_a?(Hash) 
        args << {} unless args.last.is_a?(Hash)
        mod.module_eval do
          @args = args
          @meta_initialization_procs = []
          extend Meta
          extend Associations
          extend Validations
        end
        mod.module_eval(&block) if block_given?
        mod.module_eval do
          initialize_associations
          initialize_validations
        end
        if meta_name = extract_meta_name(*args)
          Object.const_set(meta_name,mod)
        end
        mod
      end

      def document(store=nil)
        store ||= StrokeDB.default_store
        raise NoDefaultStoreError.new unless store
        unless meta_doc = store.find(NIL_UUID)
          meta_doc = Document.create!(store,:name => Meta.name, :uuid => NIL_UUID)
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

    CALLBACKS = %w(on_initialization before_save after_save when_slot_not_found on_new_document)
    CALLBACKS.each do |callback_name|
      module_eval %{
        def #{callback_name}(uid=nil,&block)
          add_callback('#{callback_name}',uid,&block)
        end
      }
    end

    def new(*args,&block)
      doc = Document.new(*args,&block)
      doc.extend(self)
      doc[:__meta__] = document(doc.store)
      setup_callbacks(doc)
      doc.send(:execute_callbacks,:on_new_document)
      doc.send(:execute_callbacks,:on_initialization)
      doc
    end

    def create!(*args,&block)
      new(*args,&block).save!
    end

    def find(*args)
      args = args.unshift(StrokeDB.default_store) if args.empty? || args.first.is_a?(Hash)
      args << {} unless args.last.is_a?(Hash)
      store = args.first
      raise NoDefaultStoreError.new unless StrokeDB.default_store
      store.search(args.last.merge(:__meta__ => document(store)))
    end

    def find_or_create(*args)
      result = find(*args)
      result.empty? ? create!(*args) : result.first
    end

    def inspect
      if is_a?(Module)
        name
      else
        pretty_print
      end
    end
    alias :to_s :inspect


    def document(store=nil)
      store ||= StrokeDB.default_store
      raise NoDefaultStoreError.new unless store
      @meta_initialization_procs.each {|proc| proc.call }
      @meta_initialization_procs.clear
      # TODO: Silly, buggy deep clone implementation!
      # Refactor this!
      args = @args.clone.map{|a| Hash === a ? a.clone : a }
      args[0] = store
      args.last[:__meta__] = Meta.document(store)
      args.last[:name] ||= name
      unless meta_doc = (store.respond_to?(:index_store) && store.index_store) ? store.search(:name => args.last[:name], 
        :__meta__ => Meta.document(store)).first : nil
        meta_doc = Document.new(*args)
        meta_doc.extend(Meta)
        meta_doc.save!
      else
        args.last[:__version__] = meta_doc.__version__
        args.last[:uuid] = meta_doc.uuid
        unless (new_doc = Document.new(*args)).to_raw == meta_doc.to_raw
          new_doc[:__previous_version__] = meta_doc.__version__
          new_doc.save!
          meta_doc = new_doc
        end
      end
      meta_doc
    end

    private

    def add_callback(name,uid=nil,&block)
      @callbacks ||= []
      @callbacks << Callback.new(self,name,uid,&block)
    end
    
    def setup_callbacks(doc)
      return unless @callbacks
      @callbacks.each do |callback|
          doc.callbacks[callback.name] ||= []
          doc.callbacks[callback.name] << callback
      end
    end
    
  end

end

