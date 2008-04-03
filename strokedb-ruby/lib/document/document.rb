module StrokeDB
  # Raised on unexisting document access.
  #
  # Example:
  #
  #  document.slot_that_does_not_exist_ever
  #
  class SlotNotFoundError < StandardError
    attr_reader :slotname
    def initialize(slotname)
      @slotname = slotname
    end
    def message
      "SlotNotFoundError: Can't find slot #{@slotname}"
    end
  end
  
  class InvalidDocumentError < StandardError #:nodoc:
    attr_reader :document
    def initialize(document)
      @document = document
    end

    def message
      "Validation failed: #{@document.errors.messages.join(", ")}"
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
    include Validations::InstanceMethods

    attr_reader :store, :callbacks  #:nodoc:

    def marshal_dump #:nodoc:
      (@new ? '1' : '0') + (@saved ? '1' : '0') + to_raw.to_json
    end
    def marshal_load(content) #:nodoc:
      @callbacks = {}
      initialize_raw_slots(JSON.parse(content[2,content.length]))
      @saved = content[1,1] == '1'
      @new = content[0,1] == '1'
    end

    # Collection of meta documents
    class Metas < Array  #:nodoc:
      def initialize(document)
        @document = document
        _meta = document[:meta]
        concat [_meta].flatten.compact.map{|v| v.is_a?(DocumentReferenceValue) ? v.load : v}
      end

      def <<(meta)
        _module = nil
        case meta
        when Document
          push meta
          _module = StrokeDB::Document.collect_meta_modules(@document.store,meta).first
        when Meta
          push meta.document(@document.store)
          _module = meta
        else
          raise ArgumentError.new("Meta should be either document or meta module")
        end
        if _module
          @document.extend(_module)
          _module.send!(:setup_callbacks,@document) rescue nil
          @document.send!(:execute_callbacks_for, _module, :on_initialization)
          @document.send!(:execute_callbacks_for, _module, :on_new_document) if @document.new?
        end
        @document[:meta] = self
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
    #    document.slotnames #=> ["version","name","language","authors"]
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
      slots = to_raw.except('meta')
      if is_a?(ImmutableDocument)
        s = "#<(imm)"
      else
        s = "#<"
      end
      Util.catch_circular_reference(self) do
        if self[:meta] && name = meta[:name]
          s << "#{name} "
        else
          s << "Doc "
        end
        slots.keys.sort.each do |k|
          if %w(version previous_version).member?(k) && v=self[k]
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
      "#(#{(self[:meta] ? "#{meta}" : "Doc")} #{('@#'+uuid)[0,5]}...)"
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
      to_raw.to_xml({ :root => 'document', :dasherize => true}.merge(opts))
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
      meta_modules = collect_meta_modules(store,raw_slots['meta'])
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
    # Find document(s) by:
    #
    # a) UUID
    #
    #    Document.find(uuid)
    #
    # b) search query
    #
    #    Document.find(:slot => "value")
    #
    # If first argument is Store, that particular store will be used; otherwise default store will be assumed.
    def self.find(*args)
      store = nil
      if args.empty? || args.first.is_a?(String) || args.first.is_a?(Hash)
        store = StrokeDB.default_store
      else
        store = args.shift
      end
      raise NoDefaultStoreError.new unless store
      query = args.first
      case query
      when /#{UUID_RE}/
        store.find(query)
      when Hash
        store.search(query)
      else
        raise TypeError
      end
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
      store.head_version(uuid) == version
    end

    #
    # Saves the document. If validations do not pass, InvalidDocumentError
    # exception is raised.
    #
    def save!(perform_validation = true)
      execute_callbacks :before_save

      if perform_validation
        raise InvalidDocumentError.new(self) unless valid?
      end

      store.save!(self)
      @new = false
      @saved = true
      execute_callbacks :after_save
      self
    end
    
    #
    # Updates slots with specified <tt>hash</tt> and returns itself.
    #
    def update_slots(hash)
      hash.each do |k, v|
        self[k] = v
      end
      self
    end

    #
    # Same as update_slots, but also saves the document.
    #
    def update_slots!(hash)
      update_slots(hash).save!
    end

    #
    # Returns document's metadocument (if any). In case if document has more than one metadocument,
    # it will combine all metadocuments into one 'virtual' metadocument
    #
    def meta
      _meta = self[:meta]
      return _meta || Document.new(@store) unless _meta.kind_of?(Array)
      return _meta.first if _meta.size == 1
      _metas = _meta.clone
      collected_meta = _metas.shift.clone
      names = []
      names = collected_meta.name.split(',') if collected_meta && collected_meta[:name]
      _metas.each do |next_meta|
        next_meta = next_meta.clone
        collected_meta += next_meta
        names << next_meta.name if next_meta[:name]
      end
      collected_meta.name = names.uniq.join(',')
      collected_meta.make_immutable!
    end

    #
    # Instantiate a composite document
    #
    def +(document)
      original, target = [to_raw,document.to_raw].map{|raw| raw.except('uuid','version','previous_version')}
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
    # Returns document's version (which is stored in <tt>version</tt> slot)
    #
    def version
      self[:version]
    end

    #
    # Return document's uuid
    #
    def uuid
      @uuid ||= self[:uuid]
    end

    #
    # Returns document's previous version (which is stored in <tt>previous_version</tt> slot)
    #
    def previous_version
      self[:previous_version]
    end

    def version=(v) #:nodoc:
      self[:version] = v
    end

    #
    # Returns an instance of Document::Versions
    #
    def versions
      @versions ||= Versions.new(self)
    end

    def __reference__ #:nodoc:
      "@##{uuid}.#{version}"
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

    def make_immutable!
      extend(ImmutableDocument)
      self
    end

    def mutable?
      true
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
        generate_new_version! unless self[:version]
      end
    end

    def initialize_slots(slots) #:nodoc:
      @slots = {}
      slots.each {|name,value| self[name] = value }
    end

    def initialize_raw_slots(slots) #:nodoc:
      @slots = {}
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
      self.version = Util.random_uuid
    end

    def update_version!(slotname)
      if @saved && slotname != 'version' && slotname != 'previous_version'
        self[:previous_version] = version unless version.nil?
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
      store.find(uuid,version)
    end

  end


  #
  # ImmutableDocument can't be saved
  # It should not be used directly
  #
  module ImmutableDocument

    def mutable?
      false
    end

    def save!
    end

  end
end
