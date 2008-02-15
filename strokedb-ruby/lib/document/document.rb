module StrokeDB
  class UnversionedDocumentError < Exception ; end
  class VersionMismatchError < Exception ; end
  class InvalidMetaDocumentError < Exception 
    attr_reader :meta_name
    def initialize(meta_name)
      @meta_name = meta_name
    end
  end
  class SlotNotFoundError < Exception 
    attr_reader :slotname
    def initialize(slotname)
      @slotname = slotname
    end
    def message
      "SlotNotFoundError: Can't find slot #{@slotname}"
    end
  end

  class Document
    attr_reader :uuid, :store, :callbacks

    #
    # doc.versions #=> #<Versions>
    # doc.versions[version_number] #=> #<Document>
    #
    class Versions
      attr_reader :document
      def initialize(document)
        @document = document
        @cache = {}
      end

      def [](version)
        @cache[version] ||= @document.store.find(document.uuid,version)
      end

      def empty?
        document.previous_version.nil?
      end
    end

    #
    # doc.metas #=> #<Metas>
    # doc.metas is an Array
    # doc.metas << Meta module
    # doc.metas << Meta document
    #
    class Metas < Array
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
          @document.send!(:execute_callbacks, :on_initialization)
        end
        @document[:__meta__] = self
      end

    end

    def self.create!(*args)
      new(*args).save!
    end

    def initialize(*args,&block)
      @initialization_block = block
      if args.first.is_a?(Hash) || args.empty?
        raise NoDefaultStoreError.new unless StrokeDB.default_store
        do_initialize(StrokeDB.default_store,*args)
      else
        do_initialize(*args)
      end
    end


    def [](slotname)
      if slot = @slots[slotname.to_s]
        slot.value
      end
    end

    def []=(slotname,value)
      slot = @slots[slotname.to_s] || @slots[slotname.to_s] = Slot.new(self)
      slot.value = value
    end

    def remove_slot!(slotname)
      @slots.delete slotname.to_s
    end

    def slotnames
      @slots.keys
    end

    def diff(from)
      Diff.new(store,:from => from, :to => self)
    end

    def to_json(opts={})
      return "\"@##{uuid}.#{version}\"" if opts[:slot_serialization]
      to_raw.to_json(opts)
    end

    def self.from_json(store,uuid,json)
      json_decoded = ActiveSupport::JSON.decode(json)
      from_raw(store,uuid,json_decoded)
    end

    def inspect
      s = "#<"
      s << (self[:__meta__] ? "#{meta} " : "Doc ")
      to_raw.except('__meta__').each_pair do |k,v|
        if %w(__version__ __previous_version__).member?(k)
          s << "#{k}: #{v.gsub(/^(0)+/,'')[0,4]}..., "
        else
          Util.catch_circular_reference(self[k]) do
            s << "#{k}: #{self[k].inspect}, "
          end
        end
      end
      s.chomp!(', ')
      s << ">"
      s
    rescue Util::CircularReferenceCondition
      "#<#{(self[:__meta__] ? "#{meta}" : "Doc")} #{uuid[0,5]}*>"
    end

    alias :to_s :inspect


    # Primary serialization

    def to_raw
      raw_slots = {}
      @slots.each_pair do |k,v|
        raw_slots[k.to_s] = v.raw_value
      end
      raw_slots
    end

    def self.from_raw(store, uuid, raw_slots,opts = {})
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

    def reload
      new? ? self : store.find(uuid)
    end

    def new?
      version.nil?
    end

    def head?
      return false if new? || is_a?(VersionedDocument)
      store.last_version(uuid) == version
    end

    def save!
      self[:__previous_version__] = store.last_version(uuid) unless new?
      execute_callbacks :before_save
      store.save!(self)
      execute_callbacks :after_save
      self
    end

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
        diff.removed_slots.clear!
        diff.patch!(collected_meta)
        names << next_meta.name if next_meta[:name] 
      end
      collected_meta.name = names.uniq.join(',')
      collected_meta
    end

    def metas
      Metas.new(self)
    end


    def previous_version
      self[:__previous_version__]
    end

    def previous_versions
      if previous_version
        [previous_version] + versions[previous_version].previous_versions
      else
        []
      end
    end

    def version
      self[:__version__]
    end

    def version=(v)
      self[:__version__] = v
    end

    def all_versions
      [version] + previous_versions
    end

    def versions
      @versions ||= Versions.new(self)
    end

    def uuid_version
      uuid + (version ? ".#{version}" : "")
    end

    def ==(doc)
      case doc
      when Document
        doc.uuid == uuid && doc.to_raw == to_raw
      when DocumentReferenceValue
        self == doc.load
      else
        false
      end
    end

    def method_missing(sym,*args,&block)
      sym = sym.to_s
      if sym.ends_with?('=')
        send(:[]=,sym.chomp('='),*args)
      else
        raise SlotNotFoundError.new(sym) unless slotnames.include?(sym)
        send(:[],sym)
      end
    end

    protected

    def execute_callbacks(name)
      (callbacks[name.to_s]||[]).each do |callback|
        callback.call(self)
      end
    end

    def do_initialize(store, slots={}, uuid=nil)
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

    def initialize_slots(slots)
      @slots = Util::HashWithSortedKeys.new
      slots.each {|name,value| self[name] = value }
    end

    def initialize_raw_slots(slots)
      @slots = Util::HashWithSortedKeys.new
      slots.each do |name,value| 
        s = Slot.new(self)
        s.raw_value = value
        @slots[name.to_s] = s
      end
    end

    def self.collect_meta_modules(store,meta)
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

  module VersionedDocument
    def to_json(opts={})
      return "\"@##{uuid_version}\"" if opts[:slot_serialization]
      _to_json = @slots
      _to_json = [uuid.to_s,@slots] if opts[:transmittal]
      _to_json.to_json(opts)
    end
    def reload
      store.find(uuid,version)
    end

  end
end