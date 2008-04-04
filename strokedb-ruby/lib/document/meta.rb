module StrokeDB
  # Meta is basically a type. Imagine the following document:
  #
  # some_apple:
  #   weight: 3oz
  #   color: green
  #   price: $3
  #
  # Each apple is a fruit and a product in this case (because it has price).
  #
  # we can express it by assigning metas to document like this:
  #
  # some_apple:
  #   meta: [Fruit, Product]
  #   weight: 3oz
  #   color: green
  #   price: $3
  #
  # In document slots metas store references to metadocument.
  #
  # Document class will be extended by modules Fruit and Product.
  module Meta

    class << self
      def new(*args,&block)
        mod = Module.new
        args = args.unshift(nil) if args.empty? || args.first.is_a?(Hash)
        args << {} unless args.last.is_a?(Hash)
        mod.module_eval do
          @args = args
          @meta_initialization_procs = []
          @metas = [self]
          extend Meta
          extend Associations
          extend Validations
          extend Coercions
          extend Virtualizations
          extend Util
        end
        mod.module_eval(&block) if block_given?
        mod.module_eval do
          initialize_associations
          initialize_validations
          initialize_coercions
          initialize_virtualizations
        end
        if meta_name = extract_meta_name(*args)
          Object.const_set(meta_name,mod)
        end
        mod
      end

      def document(store=nil)
        raise NoDefaultStoreError.new unless store ||= StrokeDB.default_store
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

    def +(meta)
      if is_a?(Module) && meta.is_a?(Module)
        new_meta = Module.new
        instance_variables.each do |iv|
          new_meta.instance_variable_set(iv,instance_variable_get(iv) ? instance_variable_get(iv).clone : nil)
        end
        new_meta.instance_variable_set(:@metas,@metas.clone)
        new_meta.instance_variable_get(:@metas) << meta
        new_meta.module_eval do
          extend Meta
        end
        new_meta_name = new_meta.instance_variable_get(:@metas).map{|m| m.name}.join('__')
        Object.send(:remove_const,new_meta_name) rescue nil
        Object.const_set(new_meta_name, new_meta)
        new_meta
      elsif is_a?(Document) && meta.is_a?(Document)
        (Document.new(store,self.to_raw.except('uuid','version','previous_version'),true) +
        Document.new(store,meta.to_raw.except('uuid','version','previous_version'),true)).extend(Meta).make_immutable!
      else
        raise "Can't + #{self.class} and #{meta.class}"
      end
    end

    CALLBACKS = %w(on_initialization before_save after_save when_slot_not_found on_new_document on_validation 
      after_validation on_set_slot)

    CALLBACKS.each do |callback_name|
      module_eval %{
        def #{callback_name}(uid=nil,&block)
          add_callback('#{callback_name}',uid,&block)
        end
      }
    end

    def new(*args,&block)
      args = args.clone
      args << {} unless args.last.is_a?(Hash)
      args.last[:meta] = @metas
      doc = Document.new(*args,&block)
      doc
    end

    def create!(*args,&block)
      new(*args,&block).save!
    end

    def find(*args)
      args = args.unshift(StrokeDB.default_store) if args.empty? || args.first.is_a?(Hash) || args.first.is_a?(String)
      return find(args.first,{:uuid => args[1]}).first if args[1].is_a?(String) && args[1].match(/#{UUID_RE}/)
      args << {} unless args.last.is_a?(Hash)
      store = args.first
      raise NoDefaultStoreError.new unless StrokeDB.default_store
      store.search(args.last.merge(:meta => @metas.map {|m| m.document(store)}))
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
      metadocs = @metas.map do |m|
        @args = m.instance_variable_get(:@args)
        make_document(store)
      end
      metadocs.size > 1 ? metadocs.inject { |a,b| a + b}.make_immutable! : metadocs.first
    end
    
    private

    def make_document(store=nil)
      raise NoDefaultStoreError.new unless store ||= StrokeDB.default_store
      @meta_initialization_procs.each {|proc| proc.call }.clear

      values = @args.clone.select{|a| Hash === a}.first
      values[:meta] = Meta.document(store)
      values[:name] ||= name
      
      if meta_doc = find_meta_doc(values, store)
        values[:version] = meta_doc.version
        values[:uuid] = meta_doc.uuid
        args = [store, values]
        meta_doc = updated_meta_doc(args) if changed?(meta_doc,args)
      else
        args = [store, values]
        meta_doc = Document.new(*args)
        meta_doc.extend(Meta)
        meta_doc.save!
      end
      meta_doc
    end

    def find_meta_doc(values, store)
      if uuid = values[:uuid]
        store.find(uuid)
      else
        store.search({ :name => values[:name], :meta => Meta.document(store) }).first
      end
    end

    def changed?(meta_doc,args)
      !(Document.new(*args).to_raw.except('previous_version') == meta_doc.to_raw.except('previous_version'))
    end
    
    def updated_meta_doc(args)
      new_doc = Document.new(*args)
      new_doc.instance_variable_set(:@saved,true)
      new_doc.send!(:update_version!,nil)
      new_doc.save!
    end

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
