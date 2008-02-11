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

    def self.create!(*args)
      new(*args).save!
    end

    def initialize(*args)
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
      if prev_version = @__previous_version__
        @__previous_version__ = nil
        self[:__previous_version__] = prev_version
      end
      set_version unless ['__version__','__lamport_timestamp__'].include?(slotname.to_s)
    end

    def remove_slot!(slotname)
      @slots.delete slotname.to_s
      set_version
      @slots.delete '__version__' if slotnames == ['__version__']
    end

    def slotnames
      @slots.keys
    end

    def diff(from)
      Diff.new(store,:from => from, :to => self)
    end

    def to_json(opts={})
      return "\"@##{uuid}\"" if opts[:slot_serialization]
      _to_json = @slots
      _to_json = [uuid.to_s,@slots] if opts[:transmittal]
      _to_json.to_json(opts)
    end

    def self.from_json(store,uuid,json)
      json_decoded = ActiveSupport::JSON.decode(json)
      from_raw(store,uuid,json_decoded)
    end

    def to_s
        Util.catch_circular_reference(self) do
        s = "<Doc "
        to_raw.each_pair do |k,v|
          if %w(__version__ __previous_version__).member?(k)
            s << "#{k}: #{v[0,5]}... "
          else
              stack = Thread.current['StrokeDB.reference_stack'] ||= []
              stack << self[k]
              s << "#{k}: #{self[k]} "
              stack.pop
          end
        end
        s << ">"
        return s
      end
      rescue Util::CircularReferenceCondition
        "<Doc #{uuid[0,5]}*>"
    end

    alias :inspect :to_s


    # Primary serialization

    def to_raw
      raw_slots = {}
      @slots.each_pair do |k,v|
        raw_slots[k.to_s] = v.raw_value 
      end
      raw_slots
    end

    def self.from_raw(store, uuid, raw_slots)
      doc = new(store, raw_slots)
      raise VersionMismatchError.new if raw_slots['__version__'] != doc.send!(:calculate_version)

      meta_modules = collect_meta_modules(store,raw_slots['__meta__'])
      meta_modules.each do |meta_module|
        doc.extend(meta_module)
        if on_initialization_block = meta_module.instance_variable_get(:@on_initialization_block)
          on_initialization_block.call(doc)
        end
      end
      doc.instance_variable_set(:@__previous_version__, doc.version)
      doc.instance_variable_set(:@uuid, uuid)
      doc
    end

    def reload
      new? ? self : store.find(uuid)
    end

    def new?
      !store.exists?(uuid)
    end

    def save!
      raise UnversionedDocumentError.new unless version
      self[:__previous_version__] ||= (@__previous_version__ || store.last_version(uuid)) unless new?
      execute_callbacks :before_save
      store.save!(self)
      execute_callbacks :after_save
      self
    end

    def meta
      _meta = self[:__meta__]
      return _meta || Document.new(@store) unless _meta.kind_of?(Array)
      metas = _meta.clone
      collected_meta = metas.shift
      metas.each do |next_meta|
        diff = next_meta.diff(collected_meta)
        diff.removed_slots.clear!
        diff.patch!(collected_meta)
      end
      collected_meta
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
      return false unless doc.is_a?(Document)
      doc.uuid == uuid && doc.version == version
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

    def do_initialize(store, slots={})
      @callbacks = {}
      @store = store
      @uuid = Util.random_uuid
      initialize_slots(slots)
    end

    def initialize_slots(slots)
      @slots = Util::HashWithSortedKeys.new
      slots.each {|name,value| self[name] = value }
    end

    def set_version
      self[:__version__] = calculate_version
    end

    def calculate_version
      Util.sha(to_json(:except => ['__version__','__lamport_timestamp__']))
    end


    def self.collect_meta_modules(store,meta)
      meta_names = []
      case meta
      when /@##{UUID_RE}.#{VERSION_RE}/
        meta_names << store.find($1,$2)[:name] if store.find($1,$2)
      when /@##{UUID_RE}/
        meta_names << store.find($1)[:name] if store.find($1)
      when Array
        meta_names = meta.map {|m| collect_meta_modules(store,m) }.flatten
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