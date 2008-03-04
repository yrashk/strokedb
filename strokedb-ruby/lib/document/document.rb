module StrokeDB
  class UnversionedDocumentError < Exception  #:nodoc:
  end
  class VersionMismatchError < Exception  #:nodoc:
  end
  class InvalidMetaDocumentError < Exception  #:nodoc:
    attr_reader :meta_name
    def initialize(meta_name)
      @meta_name = meta_name
    end
  end
  class SlotNotFoundError < Exception  #:nodoc:
    attr_reader :slotname
    def initialize(slotname)
      @slotname = slotname
    end
    def message
      "SlotNotFoundError: Can't find slot #{@slotname}"
    end
  end

  # Document is one of the core classes. It is being used to represent database document.
  # 
  # Database document is an entity that:
  # 
  # * is uniquely identified with UUID
  # * has a number of slots, where each slot is a key-value pair (whereas pair could be a JSON object)
  #
  # Here is a simplistic example of document:
  #
  # <tt>1e3d02cc-0769-4bd8-9113-e033b246b013:</tt>
  #    name: "My Document"
  #    language: "English"
  #    authors: ["Yurii Rashkovskii","Oleg Andreev"]
  #   
  class Document
    attr_reader :uuid, :store, :callbacks  #:nodoc:

    #
    # Versions is a helper class that is used to navigate through versions. You should not
    # instantiate it directly, but using Document#__versions__ method
    # 
    class Versions
      attr_reader :document
      def initialize(document)  #:nodoc:
        @document = document
        @cache = {}
      end

      #
      # Find document by version
      #
      def [](version)
        @cache[version] ||= @document.store.find(document.uuid,version)
      end
      
      #
      # Get document's previous version
      #
      # Returns <tt>nil</tt> if there is no previous version
      #
      def previous
        self[document.__previous_version__]
      end

      #
      # Find all document versions, treating current one as a head
      #
      def all
        [document.__version__,*all_preceding]
      end
      
      
      #
      # Find all _previous_ document versions, treating current one as a head
      #
      def all_preceding
        if previous_version = document.__previous_version__
          [previous_version, *self[previous_version].__versions__.all_preceding]
        else
          []
        end
      end

      #
      # Returns <tt>true</tt> if document has no previous versions
      #
      def empty?
        document.__previous_version__.nil?
      end
    end

    class Metas < Array  #:nodoc:
      def initialize(document)
        @document = document
        _meta = document[:__meta__]
        concat [_meta].flatten
      end

      def <<(meta)
        _module = nil
        case meta
        when Document
          push meta
          _module = StrokeDB::Document.collect_meta_modules(@document.store,meta).first
        when Meta
          push meta.document
          _module = meta
        else
          raise InvalidMetaDocumentError.new # FIXME: may be we should use another Error?
        end
        if _module
          @document.extend(_module)
          _module.send!(:setup_callbacks,@document) rescue nil
          @document.send!(:execute_callbacks_for, _module, :on_initialization)
        end
        @document[:__meta__] = self
      end

    end

    #
    # Instantiates new document with given arguments (which are the same as in Document#new),
    # and saves it right away
    #
    def self.create!(*args,&block)
      new(*args,&block).save!
    end

    #
    # Instantiates new document
    # 
    # Here are few ways to call it:
    #
    #    Document.new(:slot_1 => slot_1_value, :slot_2 => slot_2_value)
    #
    # This way new document with slots <tt>slot_1</tt> and <tt>slot_2</tt> will be initialized in the
    # default store.
    #
    #    Document.new(store,:slot_1 => slot_1_value, :slot_2 => slot_2_value)
    #
    # This way new document with slots <tt>slot_1</tt> and <tt>slot_2</tt> will be initialized in the
    # given <tt>store</tt>.
    #
    #    Document.new({:slot_1 => slot_1_value, :slot_2 => slot_2_value},uuid)
    #
    # where <tt>uuid</tt> is a string with UUID. *WARNING*: this way of initializing Document should not
    # be used unless you know what are you doing!
    #
    def initialize(*args,&block)
      @initialization_block = block
      if args.first.is_a?(Hash) || args.empty?
        raise NoDefaultStoreError.new unless StrokeDB.default_store
        do_initialize(StrokeDB.default_store,*args)
      else
        do_initialize(*args)
      end
    end


    # 
    # Get slot value by its name:
    #   
    #   document[:slot_1]
    #
    # If slot was not found, it will return <tt>nil</tt>
    #
    def [](slotname)
      if slot = @slots[slotname.to_s]
        slot.value
      end
    end

    # 
    # Set slot value by its name:
    #
    #   document[:slot_1] = "some value"
    #
    def []=(slotname,value)
      slot = @slots[slotname.to_s] || @slots[slotname.to_s] = Slot.new(self)
      slot.value = value
    end

    #
    # Checks slot presence. Unlike Document#slotnames it allows you to find even 'virtual slots' that could be 
    # computed runtime by associations or <tt>when_slot_found</tt> callbacks
    #
    #   document.has_slot?(:slotname)
    #
    def has_slot?(slotname)
      v = send(slotname)
      return true if v.nil? && slotnames.include?(slotname.to_s)
      !!v
    rescue SlotNotFoundError
      false
    end

    #
    # Removes slot
    #
    #    document.remove_slot!(:slotname)
    #
    def remove_slot!(slotname)
      @slots.delete slotname.to_s
    end

    # 
    # Returns an <tt>Array</tt> of explicitely defined slots
    #
    #    document.slotnames #=> ["__version__","name","language","authors"]
    #
    def slotnames
      @slots.keys
    end

    #
    # Creates Diff document from <tt>from</tt> document to this document
    #
    #    document.diff(original_document) #=> #<StrokeDB::Diff added_slots: {"b"=>2}, from: #<Doc a: 1>, removed_slots: {"a"=>1}, to: #<Doc b: 2>, updated_slots: {}>
    #
    def diff(from)
      Diff.new(store,:from => from, :to => self)
    end

    def pretty_print #:nodoc:
      slots = to_raw.except('__meta__')
      s = "#<"
      Util.catch_circular_reference(self) do
        if self[:__meta__] && meta[:name] 
          s << "#{meta.name} "
        else
          s << "Doc "
        end
        slots.each_pair do |k,v|
          if %w(__version__ __previous_version__).member?(k) && v
            s << "#{k}: #{v.gsub(/^(0)+/,'')[0,4]}..., "
          else
            s << "#{k}: #{self[k].inspect}, "
          end
        end
        s.chomp!(', ')
        s.chomp!(' ')
        s << ">"
        s
      end
      s
    rescue Util::CircularReferenceCondition
      "#(#{(self[:__meta__] ? "#{meta}" : "Doc")} #{('@#'+uuid)[0,5]}...)"
    end

    alias :to_s :pretty_print
    alias :inspect :pretty_print


    #
    # Returns string with Document's JSON representation
    #
    def to_json
      to_raw.to_json
    end
    
    #
    # Returns string with Document's XML representation
    #
    def to_xml(opts={})
      to_raw.to_xml({ :root => 'document', :dasherize => false}.merge(opts))
    end
    
    # Primary serialization

    def to_raw #:nodoc:
      raw_slots = {}
      @slots.each_pair do |k,v|
        raw_slots[k.to_s] = v.to_raw
      end
      raw_slots
    end
    
    def to_optimized_raw #:nodoc:
      __reference__
    end

    def self.from_raw(store, uuid, raw_slots,opts = {}) #:nodoc:
      doc = new(store, raw_slots, uuid)
      # doc.instance_variable_set(:@uuid, uuid)
      meta_modules = collect_meta_modules(store,raw_slots['__meta__'])
      meta_modules.each do |meta_module|
        unless doc.is_a?(meta_module)
          doc.extend(meta_module)
          meta_module.send!(:setup_callbacks,doc) rescue nil
        end
      end
      doc.send!(:execute_callbacks,:on_initialization) unless opts[:skip_callbacks]
      doc
    end

    #
    # Reloads head of the same document from store. All unsaved changes will be lost!
    #
    def reload
      new? ? self : store.find(uuid)
    end

    # 
    # Returns <tt>true</tt> if this is a document that has never been saved. 
    # 
    def new?
      __version__.nil?
    end

    #
    # Returns <tt>true</tt> if this document is a latest version of document being saved to a respective
    # store
    #
    def head?
      return false if new? || is_a?(VersionedDocument)
      store.last_version(uuid) == __version__
    end

    #
    # Saves document
    #
    def save!
      execute_callbacks :before_save
      self[:__previous_version__] = self[:__version__] unless new? 
      store.save!(self)
      execute_callbacks :after_save
      self
    end

    #
    # Returns document's metadocument (if any). In case if document has more than one metadocument,
    # it will combine all metadocuments into one 'virtual' metadocument
    #
    def meta
      _meta = self[:__meta__]
      return _meta || Document.new(@store) unless _meta.kind_of?(Array)
      _metas = _meta.to_a
      collected_meta = _metas.shift
      collected_meta = store.find(collected_meta[2,collected_meta.length]) if collected_meta.is_a?(String)
      names = []
      names = collected_meta.name.split(',') if collected_meta && collected_meta[:name]
      _metas.each do |next_meta|
        next_meta = store.find(next_meta[2,next_meta.length]) if next_meta.is_a?(String)
        diff = next_meta.diff(collected_meta)
        diff.removed_slots = {}
        diff.patch!(collected_meta)
        names << next_meta.name if next_meta[:name] 
      end
      collected_meta.name = names.uniq.join(',')
      collected_meta
    end

    #
    # Should be used to add metadocuments on the fly:
    # 
    #   document.metas << Buyer
    #   document.metas << Buyer.document
    #
    # Please not that it accept both meta modules and their documents, there is no difference
    #
    def metas
      Metas.new(self)
    end


    #
    # Returns current document's version (which is stored in <tt>__version__</tt> slot)
    #
    def __version__
      self[:__version__]
    end

    #
    # Returns current document's previous version (which is stored in <tt>__previous_version__</tt> slot)
    #
    def __previous_version__
      self[:__previous_version__]
    end

    def __version__=(v) #:nodoc:
      self[:__version__] = v
    end

    #
    # Returns an instance of Document::Versions
    #
    def __versions__
      @versions ||= Versions.new(self)
    end

    def __reference__ #:nodoc:
      "@#" + uuid + (__version__ ? ".#{__version__}" : "")
    end

    def ==(doc) #:nodoc:
      case doc
      when Document
        doc.uuid == uuid && doc.to_raw == to_raw
      when DocumentReferenceValue
        self == doc.load
      else
        false
      end
    end

    def method_missing(sym,*args,&block) #:nodoc:
      sym = sym.to_s
      if sym.ends_with?('=')
        send(:[]=,sym.chomp('='),*args)
      else
        unless slotnames.include?(sym) 
          if sym.ends_with?('?')
            !!send(sym.chomp('?'),*args,&block)
          else
            raise SlotNotFoundError.new(sym) if (callbacks['when_slot_not_found']||[]).empty?
            r = execute_callbacks(:when_slot_not_found,sym)
            raise r if r.is_a?(SlotNotFoundError) # TODO: spec this behavior
            r
          end
        else
          send(:[],sym)
        end
      end
    end
    
    def add_callback(callback) #:nodoc:
      self.callbacks[callback.name] ||= []
      if callback.uid && old_cb = self.callbacks[callback.name].find{|cb| cb.uid == callback.uid}
        self.callbacks[callback.name].delete old_cb
      end
      self.callbacks[callback.name] << callback
    end

    protected

    def execute_callbacks(name,*args) #:nodoc:
      val = nil
      (callbacks[name.to_s]||[]).each do |callback|
        val = callback.call(self,*args)
      end
      val
    end
    
    def execute_callbacks_for(origin,name,*args) #:nodoc:
      val = nil
      (callbacks[name.to_s]||[]).each do |callback|
        val = callback.call(self,*args) if callback.origin == origin
      end
      val
    end
    
    def do_initialize(store, slots={}, uuid=nil) #:nodoc:
      @callbacks = {}
      @store = store
      if uuid && uuid.match(/#{UUID_RE}/)
        @uuid = uuid
        initialize_raw_slots(slots)
      else
        @uuid = Util.random_uuid
        initialize_slots(slots)
      end
    end

    def initialize_slots(slots) #:nodoc:
      @slots = Util::HashWithSortedKeys.new
      slots.each {|name,value| self[name] = value }
    end

    def initialize_raw_slots(slots) #:nodoc:
      @slots = Util::HashWithSortedKeys.new
      slots.each do |name,value| 
        s = Slot.new(self)
        s.raw_value = value
        @slots[name.to_s] = s
      end
    end

    def self.collect_meta_modules(store,meta) #:nodoc:
      meta_names = []
      case meta
      when /@##{UUID_RE}.#{VERSION_RE}/
        if m = store.find($1,$2); meta_names << m[:name]; end 
      when /@##{UUID_RE}/
        if m = store.find($1);    meta_names << m[:name]; end 
      when Array
        meta_names = meta.map {|m| collect_meta_modules(store,m) }.flatten
      when Document
        meta_names << meta[:name]
      end
      meta_names.collect {|m| m.is_a?(String) ? (m.constantize rescue nil) : m }.compact
    end

  end

  #
  # VersionedDocument is a module that is being added to all document's of specific version.
  # It should not be accessed directly
  #
  module VersionedDocument

    #
    # Reloads the same version of the same document from store. All unsaved changes will be lost!
    #
    def reload
      store.find(uuid,__version__)
    end

  end
end