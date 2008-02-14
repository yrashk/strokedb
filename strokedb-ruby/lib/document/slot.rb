module StrokeDB
  module ArrayWithLazyDocumentLoader
  end

  module HashWithLazyDocumentLoader
  end

  class DocumentReferenceValue < String
    attr_reader :doc
    def initialize(str,doc)
      @doc = doc
      @str = str
      super(str)
    end
    def load
      case self
      when /@##{UUID_RE}.0000000000000000#{UUID_RE}/
        @cached_value || ((@cached_value = doc.store.find($1)) && (doc.head? && @cached_value = @cached_value) || (@cached_value && @cached_value.versions[@cached_value.all_versions.last])) || self
      when /@##{UUID_RE}.#{VERSION_RE}/
        if doc.head?
          @cached_value || @cached_value = doc.store.find($1) || "@##{$1}.#{$2}"
        else
          @cached_value || @cached_value = doc.store.find($1,$2) || "@##{$1}.#{$2}"
        end
      end
    end
    def inspect
      "#<DocRef #{self[0,5]}..>"
    end
  end

  class Slot
    attr_reader :doc, :value

    def initialize(doc)
      @doc = doc
    end

    def value=(v)
      @value = v
      if v.is_a?(Document) 
        @cached_value = v
      end
    end
    
    def value
      @value.is_a?(DocumentReferenceValue) ? @value.load : @value
    end

    def to_json(opts={})
      @value.to_json(opts.merge(:slot_serialization => true))
    end

    def raw_value
      result = encode_value(@value)
      case result
      when Array
        result.map{|v| v}
      else
        result
      end
    end

    def raw_value=(v)
      self.value = decode_value(v)
    end

    private

    def encode_value(v)
      case v
      when VersionedDocument
        DocumentReferenceValue.new("@##{v.uuid}.#{v.version}",doc)
      when Document
        v.new? ? DocumentReferenceValue.new("@##{v.uuid}.0000000000000000#{v.store.uuid}",doc) : DocumentReferenceValue.new("@##{v.uuid}.#{v.version}",doc)
      when Array
        LazyMappingArray.new(v) do |element| 
          element.is_a?(Document) ? encode_value(element) : element
        end
      else
        v
      end
    end

    def decode_value(v)
      case v
      when /@##{UUID_RE}.0000000000000000#{UUID_RE}/
        DocumentReferenceValue.new(v,doc)
      when /@##{UUID_RE}.#{VERSION_RE}/
        DocumentReferenceValue.new(v,doc)
      when Array
        LazyMappingArray.new(v) do |element| 
          element.is_a?(DocumentReferenceValue) ? element.load : element
        end
      when Hash
        # v.each_pair do |key, val|
        #   v[key] = decode_value(val)
        # end
        v
      else
        v
      end
    end

  end

end
