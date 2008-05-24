module StrokeDB
  
  META_CACHE = {}
  
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

      def resolve_uuid_name(nsurl,name)
        "meta:#{nsurl}##{name}"
      end

      def make_uuid_from_fullname(full_name)
        ::StrokeDB::Util.sha1_uuid(full_name)
      end
      
      def make_uuid(nsurl, name)
        ::StrokeDB::Util.sha1_uuid("meta:#{nsurl}##{name}")
      end
      
      def new(*args, &block)
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
        if name = args.last.stringify_keys['name']
          META_CACHE[make_uuid(args.last.stringify_keys['nsurl'],args.last.stringify_keys['name'])] = mod 
          mod.instance_eval %{
            def name 
              '#{name}'
            end
          }
        end
        mod
      end

      def document(store=nil)
        raise NoDefaultStoreError.new unless store ||= StrokeDB.default_store
        unless meta_doc = store.find(meta_uuid)
          meta_doc = Document.create!(store, :name => Meta.name.demodulize, :uuid => meta_uuid, :nsurl => StrokeDB.nsurl)
        end
        meta_doc
      end
      


      def meta_uuid
        @uuid ||= ::StrokeDB::Util.sha1_uuid("meta:#{StrokeDB.nsurl}##{Meta.name.demodulize}")
      end

    end

    def implements(another_meta)
      values = @args.find{|a| a.is_a?(Hash) }
      values.merge!(another_meta.document.to_raw.delete_if {|k,v| ['name','uuid','version','previous_version','meta'].member?(k) })
      values[:implements_metas] ||= []
      values[:implements_metas] << another_meta.document
      include(another_meta)
      self
    end
    
    def +(meta)
      if is_a?(Module) && meta.is_a?(Module)
        new_meta = Module.new
        instance_variables.each do |iv|
          new_meta.instance_variable_set(iv, instance_variable_get(iv) ? instance_variable_get(iv).clone : nil)
        end
        new_meta.instance_variable_set(:@metas, @metas.clone)
        new_meta.instance_variable_get(:@metas) << meta
        new_meta.module_eval do
          extend Meta
        end
        new_meta_name = new_meta.instance_variable_get(:@metas).map{|m| m.name.demodulize}.join('__')
        mod = self.name.modulize.constantize rescue Object
        mod.send(:remove_const, new_meta_name) rescue nil
        mod.const_set(new_meta_name, new_meta)
        new_meta
      elsif is_a?(Document) && meta.is_a?(Document)
        (Document.new(store, self.to_raw.except('uuid','version','previous_version'), true) +
        Document.new(store, meta.to_raw.except('uuid','version','previous_version'), true)).extend(Meta).make_immutable!
      else
        raise "Can't + #{self.class} and #{meta.class}"
      end
    end
    
    def named(*args,&block)
      args.unshift StrokeDB.default_store unless args.first.is_a?(StrokeDB::Store)
      args << {} unless args.last.is_a?(Hash)
      raise ArgumentError, "you should specify name" unless args[1].is_a?(String)
      name = args[1]
      uuid = ::StrokeDB::Util.sha1_uuid("#{document(args[0]).uuid}:#{name}")
      unless doc = find(args[0],uuid,&block)
        doc = create!(args[0],args.last.reverse_merge(:uuid => uuid),&block)
      else
        doc.update_slots!(args.last)
      end
      doc
    end

    CALLBACKS = %w(on_initialization 
                   on_load 
                   before_save 
                   after_save 
                   when_slot_not_found 
                   on_new_document 
                   on_validation 
                   after_validation 
                   on_set_slot)

    CALLBACKS.each do |callback_name|
      module_eval %{
        def #{callback_name}(uid=nil, &block)
          add_callback('#{callback_name}', uid, &block)
        end
      }
    end

    def new(*args, &block)
      args = args.clone
      args << {} unless args.last.is_a?(Hash)
      args.last[Meta] = @metas
      doc = Document.new(*args, &block)
      doc
    end

    def create!(*args, &block)
      new(*args, &block).save!
    end
 
    #
    # Finds all documents matching given parameters. The simplest form of
    # +find+ call is without any parameters. This returns all documents
    # belonging to the meta as an array.
    #
    #   User = Meta.new
    #   all_users = User.find
    # 
    # Another form is to find a document by its UUID:
    #
    #   specific_user = User.find("1e3d02cc-0769-4bd8-9113-e033b246b013")
    #
    # If the UUID is not found, nil is returned.
    #
    # Most prominent search uses slot values as criteria:
    #
    #   short_fat_joes = User.find(:name => "joe", :weight => 110, :height => 167)
    # 
    # All matching documents are returned as an array.
    #
    # In all described cases the default store is used. You may also specify
    # another store as the first argument:
    #
    #   all_my_users = User.find(my_store)
    #   all_my_joes  = User.find(my_store, :name => "joe")
    #   oh_my        = User.find(my_store, "1e3d02cc-0769-4bd8-9113-e033b246b013")
    #
    def find(*args, &block)
      if args.empty? || !args.first.respond_to?(:search)
        raise NoDefaultStoreError unless StrokeDB.default_store
        
        args = args.unshift(StrokeDB.default_store) 
      end

      unless args.size == 1 || args.size == 2
        raise ArgumentError, "Invalid arguments for find"
      end

      store = args[0]
      opt = { Meta => @metas.map {|m| m.document(store)} }

      case args[1]
      when String
        raise ArgumentError, "Invalid UUID" unless args[1].match(UUID_RE)
        store.find(args[1], &block)
      when Hash
        store.search opt.merge(args[1])
      when nil
        store.search opt
      else
        raise ArgumentError, "Invalid search criteria for find"
      end
    end

    # Convenience alias for Meta#find.
    #
    alias :all :find

    #
    # Similar to +find+, but creates a document with an appropriate 
    # slot values if document was not found.
    #
    # If found, returned is only the first result.
    #
    def find_or_create(*args, &block)
      result = find(*args)
      result.empty? ? create!(*args, &block) : result.first
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
      metadocs.size > 1 ? metadocs.inject { |a, b| a + b }.make_immutable! : metadocs.first
    end
    
  
  
    def extended(obj)
        setup_callbacks(obj) if obj.is_a?(Document)
    end
    
    def meta_uuid
      values = @args.clone.select{|a| a.is_a?(Hash) }.first
      values[:nsurl] ||= name.modulize.empty? ? Module.nsurl : name.modulize.constantize.nsurl 
      values[:name] ||= name.demodulize
      
      @uuid ||= Meta.make_uuid(values[:nsurl],values[:name])
    end
    
    
    
    private
    
    def make_document(store=nil)
      raise NoDefaultStoreError.new unless store ||= StrokeDB.default_store
      @meta_initialization_procs.each {|proc| proc.call }.clear

      values = @args.clone.select{|a| a.is_a?(Hash) }.first
      values[Meta] = Meta.document(store)
      values[:name] ||= name.demodulize

      raise ArgumentError, "meta can't be nameless" if values[:name].blank?

      values[:nsurl] ||= name.modulize.empty? ? Module.nsurl : name.modulize.constantize.nsurl 
      values[:uuid] ||= meta_uuid
      
      
      if meta_doc = store.find(meta_uuid)
        values[:version] = meta_doc.version
        values[:uuid] = meta_doc.uuid
        args = [store, values]
        meta_doc = updated_meta_doc(args) if changed?(meta_doc, args)
      else
        args = [store, values]
        meta_doc = Document.new(*args)
        meta_doc.save!
      end
      meta_doc
    end

    def changed?(meta_doc, args)
      !(Document.new(*args).to_raw.except('previous_version') == meta_doc.to_raw.except('previous_version'))
    end
    
    def updated_meta_doc(args)
      new_doc = Document.new(*args)
      new_doc.instance_variable_set(:@saved, true)
      new_doc.send!(:update_version!, nil)
      new_doc.save!
    end

    def add_callback(name,uid=nil, &block)
      @callbacks ||= []
      @callbacks << Callback.new(self, name, uid, &block)
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
