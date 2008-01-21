module StrokeDB
  class Document
    attr_reader :uuid, :store

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
      set_version unless slotname == :__version__ 
    end
    
    def slotnames
      @slots.keys
    end

    def to_json(opts={})
      _to_json = @slots
      _to_json = [uuid.to_s,@slots] if opts[:transmittal]
      _to_json.to_json(opts)
    end

    def to_s
      to_json
    end

    def new?
      !store.exists?(uuid)
    end

    def save!
      self[:__previous_version__] = store.last_version(uuid) unless new?
      store.save!(self)
    end

    def previous_versions
      if prev_version = self[:__previous_version__]
        [prev_version] + store.find(uuid,prev_version).previous_versions
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

  protected

    def initialize_slots(slots)
      @slots = Util::HashWithSortedKeys.new
      slots.each {|name,value| self[name] = value }
    end

    def set_version
      self[:__version__] = Util.sha(to_json(:except => '__version__'))
    end

    def after_initialize
    end

  end
end