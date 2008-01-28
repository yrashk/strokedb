module StrokeDB
  class UnversionedDocumentError < Exception ; end
  class VersionMismatchError < Exception ; end
  class Document
    attr_reader :uuid, :store

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

    def self.create(store, slots={})
      new(store,slots).save!
    end
    
    def initialize(store, slots={})
      @store = store
      @uuid = Util.random_uuid
      initialize_slots(slots)
      after_initialize
    end

    def [](slotname)
      if slot = @slots[slotname.to_s]
        slot.value
      end
    end

    def []=(slotname,value)
      slot = @slots[slotname.to_s] || @slots[slotname.to_s] = Slot.new(self)
      slot.value = value
      if @__previous_version__
        prev_version = @__previous_version__ ; @__previous_version__ = nil
        self[:__previous_version__] = prev_version
      end
      set_version unless slotname == :__version__ 
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
      Diff.new(store,from,self)
    end

    def to_json(opts={})
      _to_json = @slots
      _to_json = [uuid.to_s,@slots] if opts[:transmittal]
      _to_json.to_json(opts)
    end
    
    def self.from_json(store,uuid,json)
      json_decoded = ActiveSupport::JSON.decode(json)
      from_raw(store,uuid,json_decoded)
    end

    def to_s
      to_json
    end
    
    
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
      doc.instance_variable_set(:@__previous_version__, doc.version)
      doc.instance_variable_set(:@uuid, uuid)
      doc
    end

    def new?
      !store.exists?(uuid)
    end

    def save!
      raise UnversionedDocumentError.new unless version
      self[:__previous_version__] ||= (@__previous_version__ || store.last_version(uuid)) unless new?
      store.save!(self)
      self
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

  protected

    def initialize_slots(slots)
      @slots = Util::HashWithSortedKeys.new
      slots.each {|name,value| self[name] = value }
    end

    def set_version
      self[:__version__] = calculate_version
    end
    
    def calculate_version
      Util.sha(to_json(:except => '__version__'))
    end

    def after_initialize
    end

  end
end