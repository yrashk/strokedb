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

    attr_reader :store, :callbacks  #:nodoc:

    def marshal_dump #:nodoc:
      (@new ? '1' : '0') + (@saved ? '1' : '0') + to_raw.to_json
    end
    def marshal_load(content) #:nodoc:
      @callbacks = {}
      initialize_raw_slots(ActiveSupport::JSON.decode(content[2,content.length]))
      @saved = content[1,1] == '1'
      @new = content[0,1] == '1'
    end
    # include DRbUndumped
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
      # Get document by version.
      #
      # Returns Document instance
      # Returns <tt>nil</tt> if there is no document with given version
      #
      def [](version)
        @cache[version] ||= @document.store.find(document.uuid,version)
      end

      #
      # Get document with previous version
      #
      # Returns Document instance
      # Returns <tt>nil</tt> if there is no previous version
      #
      def previous
        self[document.__previous_version__]
      end

      #
      # Find all document versions, treating current one as a head
      #
      # Returns an Array of version numbers
      #
      def all_versions
        [document.__version__,*all_preceding_versions]
      end

      #
      # Get all versions of document including currrent one
      #
      # Returns an Array of Documents
      #
      def all
        all_versions.map{|v| self[v]}
      end


      #
      # Find all _previous_ document versions, treating current one as a head
      #
      # Returns an Array of version numbers
      #
      def all_preceding_versions
        if previous_version = document.__previous_version__
          [previous_version, *self[previous_version].__versions__.all_preceding_versions]
        else
          []
        end
      end

      #
      # Find all previous versions of document
      #
      # Returns an Array of Documents
      #
      def all_preceding
        all_preceding_versions.map{|v| self[v]}
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
          @document.send!(:execute_callbacks_for, _module, :on_new_document) if @document.new?
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
      slotname = slotname.to_s
      slot = @slots[slotname] || @slots[slotname] = Slot.new(self)
      slot.value = value
      update_version!(slotname)
      slot.value
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
      update_version!(slotname)
      nil
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
        slots.keys.sort.each do |k|
          if %w(__version__ __previous_version__).member?(k) && v=self[k]
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

    def self.from_raw(store,raw_slots,opts = {}) #:nodoc:
      doc = new(store, raw_slots, true)
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
      !!@new
    end

    #
    # Returns <tt>true</tt> if this document is a latest version of document being saved to a respective
    # store
    #
    def head?
      return false if new? || is_a?(VersionedDocument)
      store.head_version(uuid) == __version__
    end

    #
    # Saves document
    #
    def save!
      execute_callbacks :before_save
      self[:__previous_version__] = __version__ if @saved
      store.save!(self)
      @new = false
      @saved = true
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
      popped = _metas.shift
      if popped.is_a?(DocumentReferenceValue) || popped.is_a?(String)
        popped.doc = self
        popped = popped.load 
      end
      collected_meta = Document.new(@store,popped.to_raw.except('uuid','__version__','__previous_version__'))
      names = []
      names = collected_meta.name.split(',') if collected_meta && collected_meta[:name]
      _metas.each do |next_meta|
        if next_meta.is_a?(DocumentReferenceValue) || next_meta.is_a?(String)
          next_meta.doc = self
          next_meta = next_meta.load 
        end
        next_meta = Document.new(@store,next_meta.to_raw.except('uuid','__version__','__previous_version__'))
        collected_meta += next_meta
        names << next_meta.name if next_meta[:name] 
      end
      collected_meta.name = names.uniq.join(',')
      collected_meta
    end
    
    #
    # Instantiate a composite document
    #
    def +(document)
      original, target = [to_raw,document.to_raw].map{|raw| raw.except('uuid','__version__','__previous_version__')}
      Document.new(@store,original.merge(target).merge(:uuid => Util.random_uuid),true)
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
    # Returns document's version (which is stored in <tt>__version__</tt> slot)
    #
    def __version__
      self[:__version__]
    end

    #
    # Return document's uuid
    #
    def uuid
      self[:uuid]
    end

    #
    # Returns document's previous version (which is stored in <tt>__previous_version__</tt> slot)
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
      "@##{uuid}.#{__version__}"
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

    def do_initialize(store, slots={}, initialize_raw = false) #:nodoc:
      @callbacks = {}
      @store = store
      if initialize_raw
        initialize_raw_slots(slots)
        @saved = true
      else
        @new = true
        initialize_slots(slots)
        self[:uuid] = Util.random_uuid unless self[:uuid]
        generate_new_version! unless self[:__version__]
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

    def generate_new_version!
      self.__version__ = Util.random_uuid
    end

    def update_version!(slotname)
      if @saved && slotname != '__version__' && slotname != '__previous_version__'
        self[:__previous_version__] = __version__
        generate_new_version!
        @saved = nil
      end
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