require 'java'
require 'rubygems'
require 'activesupport'

module StrokeDB

  class Slot
    attr_reader :doc
    
    def initialize(doc)
      @doc = doc
    end
    
    def value=(v)
      case v
        when Document
        @value = "@##{v.uuid}"
        @cached_value = v # lets cache it locally
      else
        @value = v
      end
    end
    
    def value
      case @value
      when /@#([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
        if doc.store.exists?($1)
          doc.store.find($1)
        else
          @cached_value || "@##{$1}" # return cache if available
        end
      else
        @value 
      end
    end
    
    def to_json(opts={})
      @value.to_json(opts)
    end
  end

  class Store
    def new_doc(slots={})
      Document.new(self,slots)
    end

    protected

    def load_doc(uuid,json)
      returning doc = Document.new(self,ActiveSupport::JSON.decode(json)) do
        doc.instance_variable_set(:@uuid, uuid.is_a?(String) ? java.util.UUID.from_string(uuid) : uuid)
      end
    end
  end

  class FileStore < Store

    attr_reader :path

    def find(uuid,version=nil)
      json = IO.read(filename(uuid,version))
      load_doc(uuid,json)
    end

    def initialize(path)
      @path = path
    end

    def exists?(uuid)
      File.exists?(filename(uuid))
    end

    def last_version(uuid)
      if exists?(uuid)
        json = IO.read(filename(uuid))
        ActiveSupport::JSON.decode(json)['__version__']
      end
    end

    def save!(doc)
      FileUtils.mkdir_p File.dirname(filename(doc.uuid))
      File.open filename(doc.uuid), "w+" do |f|
        f.write doc.to_json
      end
      File.open filename(doc.uuid,doc[:__version__]), "w+" do |f|
        f.write doc.to_json
      end
    end

    private

    def filename(uuid,version=nil)
      
      uuid_s = uuid.to_s
      File.join(path,[uuid_s[0,2], uuid_s[2,2], uuid_s[4,2], uuid_s.slice(6,30).gsub('-','')].join('/') + (version ? ".#{version}" : "") )
    end

  end

  class Document
    attr_reader :uuid, :store

    def initialize(store,slots={})
      @store = store
      @uuid = java.util.UUID.randomUUID
      @slots = {}
      initialize_slots(slots)
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

    def to_json(opts={})
       @slots.to_json(opts)
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

    private

    def initialize_slots(slots)
      slots.each {|name,value| self[name] = value }
    end

    def set_version
      md = java.security.MessageDigest.get_instance("SHA-256")
      md.update to_json(:except => ['__version__']).to_java_bytes
      self[:__version__] = md.digest.to_a.collect{|i| java.lang.Integer.to_hex_string(i & 0xff) }.join
    end

  end

end

if __FILE__ == $0
  store = StrokeDB::FileStore.new "db"
  _d = nil
  100.times do |i|
    _d1 = store.new_doc :welcome => 1
    _d = store.new_doc :hello => "once#{i}", :__meta__ => "Beliberda", :_d1 => _d1
    _d.save!
    _d1.save!
  end

  puts "last saved:"
  d_ = store.find(_d.uuid)
  puts store.send!(:filename,_d.uuid)
  puts d_
  d_[:something] = 1
  d_.save!
  puts d_
  puts "----"
  d_[:something_else] = 2
  d_.save!
  puts d_
  puts d_[:_d1]
  puts d_.previous_versions.inspect
end

