require 'document/validations'
require 'document/virtualize'
require 'document/util'
require 'document/meta'
require 'document/associations'
require 'document/callback'
require 'document/coercions'
require 'document/delete'
require 'document/slot'
require 'document/versions'

module StrokeDB
  # Slots which contain references to another documents are matched
  # with these regexps.
  DOCREF = /^@##{UUID_RE}$/
  VERSIONREF = /^@##{UUID_RE}\.#{VERSION_RE}$/

  #
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
      "Can't find slot #{@slotname}"
    end

    def inspect
      "#<#{self.class.name}: #{message}>"
    end
  end

  #
  # Raised when Document#save! is called on an invalid document 
  # (for which doc.valid? returns false)
  #
  class InvalidDocumentError < StandardError #:nodoc:
    attr_reader :document

    def initialize(document)
      @document = document
    end

    def message
      "Validation failed: #{@document.errors.messages.join(", ")}"
    end

    def inspect
      "#<#{self.class.name}: #{message}>"
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
    include StrokeDB::Validations::InstanceMethods

    attr_reader :callbacks  #:nodoc:

    def store
      if (txns = Thread.current[:strokedb_transactions]) && !txns.nil? && !txns.empty?
        txns.last
      else
        @store
      end
    end

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
        add_meta(meta, :call_initialization_callbacks => true)
      end
      
      alias :_delete :delete
      def delete(meta)
        case meta
        when Document
          _delete meta
          _module = StrokeDB::Document.collect_meta_modules(@document.store, meta).first
        when Meta
          _delete meta.document(@document.store)
          _module = meta
        else
          raise ArgumentError, "Meta should be either document or meta module"
        end
        
        @document[:meta] = self
        
        if _module
          @document.unextend(_module)
        end
        
      end

      def add_meta(meta, opts = {})
        opts = opts.stringify_keys
        _module = nil

        # meta can be specified both as a meta document and as a module
        case meta
        when Document
          push meta
          _module = StrokeDB::Document.collect_meta_modules(@document.store, meta).first
        when Meta
          push meta.document(@document.store)
          _module = meta
        else
          raise ArgumentError, "Meta should be either document or meta module"
        end

        # register meta in the document
        @document[:meta] = self

        if _module
          @document.extend(_module)

          _module.send!(:setup_callbacks, @document) rescue nil

          if opts['call_initialization_callbacks'] 
            @document.send!(:execute_callbacks_for, _module, :on_initialization)
            @document.send!(:execute_callbacks_for, _module, :on_new_document) if @document.new?
          end
        end
      end
    end

    #
    # Instantiates new document with given arguments (which are the same as in Document#new),
    # and saves it right away
    #
    def self.create!(*args, &block)
      new(*args, &block).save!
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
    def initialize(*args, &block)
      @initialization_block = block

      if args.first.is_a?(Hash) || args.empty?
        raise NoDefaultStoreError unless StrokeDB.default_store
        do_initialize(StrokeDB.default_store, *args)
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
      @slots[slotname.to_s].value rescue nil
    end

    #
    # Set slot value by its name:
    #
    #   document[:slot_1] = "some value"
    #
    def []=(slotname, value)
      slotname = slotname.to_s

      (@slots[slotname] ||= Slot.new(self, slotname)).value = value
      update_version!(slotname)

      value
    end

    #
    # Checks slot presence. Unlike Document#slotnames it allows you to find even 'virtual slots' that could be
    # computed runtime by associations or <tt>when_slot_found</tt> callbacks
    #
    #   document.has_slot?(:slotname)
    #
    def has_slot?(slotname)
      v = send(slotname)

      (v.nil? && slotnames.include?(slotname.to_s)) ? true : !!v
    rescue SlotNotFoundError
      false
    end

    #
    # Removes slot
    #
    #    document.remove_slot!(:slotname)
    #
    def remove_slot!(slotname)
      slotname = slotname.to_s

      @slots.delete slotname
      update_version! slotname

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
      Diff.new(store, :from => from, :to => self)
    end

    def pretty_print #:nodoc:
      slots = to_raw.except('meta')

      s = is_a?(ImmutableDocument) ? "#<(imm)" : "#<"

      Util.catch_circular_reference(self) do
        if self[:meta] && name = meta[:name]
          s << "#{name} "
        else
          s << "Doc "
        end

        slots.keys.sort.each do |k|
          if %w(version previous_version).member?(k) && v = self[k]
            s << "#{k}: #{v.gsub(/^(0)+/,'')[0,4]}..., "
          else
            s << "#{k}: #{self[k].inspect}, "
          end
        end

        s.chomp!(', ')
        s.chomp!(' ')
        s << ">"
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
    def to_xml(opts = {})
      to_raw.to_xml({ :root => 'document', :dasherize => true }.merge(opts))
    end

    #
    # Primary serialization
    #
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

    #
    # Creates a document from a serialized representation
    #
    def self.from_raw(store, raw_slots, opts = {}) #:nodoc:
      doc = new(store, raw_slots, true)

      collect_meta_modules(store, raw_slots['meta']).each do |meta_module|
        unless doc.is_a? meta_module
          doc.extend(meta_module)

          meta_module.send!(:setup_callbacks, doc) rescue nil
        end
      end

      unless opts[:skip_callbacks]
        doc.send! :execute_callbacks, :on_initialization
        doc.send! :execute_callbacks, :on_load
      end
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
      if (txns = Thread.current[:strokedb_transactions]) && !txns.nil? && !txns.empty?
        store = txns.last
      else
        if args.empty? || args.first.is_a?(String) || args.first.is_a?(Hash) || args.first.nil?
          store = StrokeDB.default_store
        else
          store = args.shift
        end
      end
      raise NoDefaultStoreError.new unless store
      query = args.first
      case query
      when UUID_RE
        store.find(query)
      when Hash
        store.search(query)
      else
        raise ArgumentError, "use UUID or query to find document(s)"
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

      execute_callbacks :after_validation

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
      unless (m = self[:meta]).kind_of? Array
        # simple case
        return m || Document.new(@store)
      end

      return m.first if m.size == 1

      mm = m.clone
      collected_meta = mm.shift.clone

      names = collected_meta[:name].split(',') rescue []

      mm.each do |next_meta|
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
      original, target = [to_raw, document.to_raw].map{ |raw| raw.except(*%w(uuid version previous_version)) }

      Document.new(@store, original.merge(target).merge(:uuid => Util.random_uuid), true)
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
      @metas ||= Metas.new(self)
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

    def raw_uuid #:nodoc:
      @raw_uuid ||= uuid.to_raw_uuid
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
      when Document, DocumentReferenceValue
        doc = doc.load if doc.kind_of? DocumentReferenceValue

        # we make a quick UUID check here to skip two heavy to_raw calls
        doc.uuid == uuid && doc.to_raw == to_raw
      else
        false
      end
    end

    def eql?(doc) #:nodoc:
      self == doc
    end

    # documents are hashed by their UUID
    def hash #:nodoc:
      uuid.hash
    end

    def make_immutable!
      extend ImmutableDocument
      self
    end

    def mutable?
      true
    end

    def method_missing(sym, *args) #:nodoc:
      sym = sym.to_s

      return send(:[]=, sym.chomp('='), *args) if sym.ends_with? '='
      return self[sym]                         if slotnames.include? sym
      return !!send(sym.chomp('?'), *args)     if sym.ends_with? '?'

      raise SlotNotFoundError.new(sym) if (callbacks['when_slot_not_found'] || []).empty?

      r = execute_callbacks(:when_slot_not_found, sym)
      raise r if r.is_a? SlotNotFoundError # TODO: spec this behavior

      r
    end

    def add_callback(cbk) #:nodoc:
      name, uid = cbk.name, cbk.uid

      callbacks[name] ||= []

      # if uid is specified, previous callback with the same uid is deleted
      if uid && old_cb = callbacks[name].find{ |cb| cb.uid == uid }
        callbacks[name].delete old_cb
      end

      callbacks[name] << cbk
    end

    protected

    # value of the last called callback is returned when executing callbacks
    # (or nil if none found)
    def execute_callbacks(name, *args) #:nodoc:
      (callbacks[name.to_s] || []).inject(nil) do |prev_value, callback|
        callback.call(self, *args)
      end
    end

    def execute_callbacks_for(origin, name, *args) #:nodoc:
      (callbacks[name.to_s] || []).inject(nil) do |prev_value, callback|
        callback.origin == origin ? callback.call(self, *args) : prev_value
      end
    end

    # initialize the document. initialize_raw is true when 
    # document is initialized from a raw serialized form
    def do_initialize(store, slots={}, initialize_raw = false) #:nodoc:
      @callbacks = {}
      @store = store

      if initialize_raw
        initialize_raw_slots slots 
        @saved = true
      else
        @new = true
        initialize_slots slots

        self[:uuid] = Util.random_uuid unless self[:uuid]
        generate_new_version!          unless self[:version]
      end
    end

    # initialize slots for a new, just created document
    def initialize_slots(slots) #:nodoc:
      @slots = {}
      slots = slots.stringify_keys

      # there is a reason for meta slot is initialized separately — 
      # we need to setup coercions before initializing actual slots
      if meta = slots['meta']
        meta = [meta] unless meta.is_a?(Array)
        meta.each {|m| metas.add_meta(m) }
      end

      slots.except('meta').each {|name,value| self[name] = value }

      # now, when we have all slots initialized, we can run initialization callbacks
      execute_callbacks :on_initialization
      execute_callbacks :on_new_document
    end

    # initialize slots from a raw representation
    def initialize_raw_slots(slots) #:nodoc:
      @slots = {}

      slots.each do |name,value|
        s = Slot.new(self, name)
        s.raw_value = value

        @slots[name.to_s] = s
      end
    end

    # returns an array of meta modules (as constants) for a given something
    # (a document reference, a document itself, or an array of the former)
    def self.collect_meta_modules(store, meta) #:nodoc:
      meta_names = []

      case meta
      when VERSIONREF
        if m = store.find($1, $2)
          meta_names << m[:name]
        end
      when DOCREF
        if m = store.find($1)
          meta_names << m[:name]
        end
      when Array
        meta_names = meta.map { |m| collect_meta_modules(store, m) }.flatten
      when Document
        meta_names << meta[:name]
      end

      meta_names.map { |m| m.is_a?(String) ? (m.constantize rescue nil) : m }.compact
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
      store.find(uuid, version)
    end
  end

  #
  # ImmutableDocument can't be saved
  # It should not be used directly, use Document#make_immutable! instead
  #
  module ImmutableDocument
    def mutable?
      false
    end

    def save!
      self
    end
  end
end