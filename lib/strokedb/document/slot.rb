require 'util/lazy_mapping_hash'
require 'util/lazy_mapping_array'

module StrokeDB
  class HashSlotValue < LazyMappingHash
    def with_modification_callback(&block)
      @modification_callback = block
      self
    end
    def []=(*args)
      super(*args)
      @modification_callback.call if @modification_callback
    end
    
  end

  class ArraySlotValue < LazyMappingArray
    def with_modification_callback(&block)
      @modification_callback = block
      self
    end
    def []=(*args)
      super(*args)
      @modification_callback.call if @modification_callback
    end
    def push(*args)
      super(*args)
      @modification_callback.call if @modification_callback
    end
    def <<(*args)
      super(*args)
      @modification_callback.call if @modification_callback
    end
    def unshift(*args)
      super(*args)
      @modification_callback.call if @modification_callback
    end

    def include?(v) 
      case v
      when VersionedDocument
        super(v)
      when Document
        v.versions.all.find{|d| super(d)} # FIXME: versions.all could be pretty slow
      else
        super(v)
      end
    end

  end

  class DocumentReferenceValue < String
    attr_reader :str
    attr_accessor :doc
    def initialize(str, doc, __cached_value = nil)
      @str, @doc = str, doc
      @cached_value = __cached_value
      super(str)
    end
    def load
      case self
      when VERSIONREF
        if doc.head?
          @cached_value || @cached_value = doc.store.find($1) || self
        else
          @cached_value || @cached_value = doc.store.find($1,$2) || self
        end
      end
    end
    def inspect
      "#<DocRef #{self[0,5]}..>"
    end
    alias :to_raw :str
    alias :to_s :str

    def ==(v)
      case v
      when DocumentReferenceValue
        v.str == str
      when Document
        v == self
      else
        str == v
      end
    end


  end

  class Slot
    attr_reader :doc, :value, :name
    
    DUMP_PREFIX    = "@!Dump:".freeze
    DUMP_PREFIX_RE = /^#{DUMP_PREFIX}/.freeze
    
    def initialize(doc, name = nil)
      @doc, @name = doc, name
      @decoded = {}
    end

    def value=(v)
      v = doc.send!(:execute_callbacks, :on_set_slot, name, v) || v unless name == 'meta'
      @value = decode_value(enforce_collections(encode_value(v, true), true))
    end

    def value
      @value.is_a?(DocumentReferenceValue) ? @value.load : @value
    end

    def to_raw
      raw_value.to_optimized_raw
    end



    def raw_value=(v)
      self.value = decode_value(v)
    end

    private

    def raw_value
      result = encode_value(@value)
      enforce_collections(result)
    end

    def encode_value(v, skip_documents=false)
      case v
      when Document
        skip_documents ? v : DocumentReferenceValue.new(v.__reference__, doc, v) 
      when Module
        if v.respond_to?(:document)
          v.document(doc.store) 
        else
          raise ArgumentError, "#{v.class} is not a valid slot value type"
        end
      when Array
        LazyMappingArray.new(v).map_with do |element| 
          encode_value(element, skip_documents)
        end.unmap_with do |element|
          decode_value(element)
        end
      when Hash
        LazyMappingHash.new(v).map_with do |element| 
          encode_value(element, skip_documents)
        end.unmap_with do |element|
          decode_value(element)
        end
      when Range, Regexp
        DUMP_PREFIX + StrokeDB::serialize(v)
      when Symbol
        v.to_s
      when String, Numeric, TrueClass, FalseClass, NilClass
        v
      when Time
        v.xmlschema(6)
      else
        raise ArgumentError, "#{v.class} is not a valid slot value type"
      end
    end

    def decode_value(v)
      case v
      when VERSIONREF
        DocumentReferenceValue.new(v.to_s, doc)
      when DUMP_PREFIX_RE
        StrokeDB::deserialize(v[7, v.length-7])
      when Array
        ArraySlotValue.new(v).map_with do |element| 
          decoded = decode_value(element)
          @decoded[decoded] ||= decoded.is_a?(DocumentReferenceValue) ? decoded.load : decoded
        end.unmap_with do |element|
          encode_value(element)
        end.with_modification_callback do
          doc.send!(:update_version!, nil)
        end
      when Hash
        HashSlotValue.new(v).map_with do |element|
          decoded = decode_value(element)
          @decoded[decoded] ||= decoded.is_a?(DocumentReferenceValue) ? decoded.load : decoded
        end.unmap_with do |element|
          encode_value(element)
        end.with_modification_callback do
          doc.send!(:update_version!, nil)
        end
      when Symbol
        v.to_s
      when XMLSCHEMA_TIME_RE
        Time.xmlschema(v).localtime # localtime is for compliance with local time objects
      else
        v
      end
    end

    def enforce_collections(v, skip_documents = false)
      return v unless v.is_a?(Array) || v.is_a?(Hash)
      case v
      when Array
        v.map{|v| enforce_collections(encode_value(v, skip_documents))}
      when Hash
        h = {}
        v.each_pair do |k, v|
          h[enforce_collections(encode_value(k, skip_documents))] = enforce_collections(encode_value(v, skip_documents))
        end
        h
      end
    end

  end

end
