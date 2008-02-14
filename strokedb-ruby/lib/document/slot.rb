module StrokeDB
  class Slot
    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def value=(v)
      @cached_value = nil
      @value = encode_value(v)
      if v.is_a?(Document) 
        @cached_value = v
      end
    end

    def value
      @cached_value ||= decode_value(@value)
    end

    def to_json(opts={})
      @value.to_json(opts.merge(:slot_serialization => true))
    end

    def raw_value
      case @value
      when Hash, Array
        @value.map {|v| encode_value(v) }
      else
        @value
      end
    end

    private

    def encode_value(v)
      case v
      when VersionedDocument
        "@##{v.uuid}.#{v.version}"
      when Document
        v.new? ? "@##{v.uuid}.0000000000000000#{v.store.uuid}" : "@##{v.uuid}.#{v.version}"
      else
        v
      end
    end

    def decode_value(v)
      case v
      when /@##{UUID_RE}.0000000000000000#{UUID_RE}/
          @cached_value || ((@cached_value = doc.store.find($1)) && (doc.head? && @cached_value = @cached_value) || (@cached_value && @cached_value.versions[@cached_value.all_versions.last])) || v
      when /@##{UUID_RE}.#{VERSION_RE}/
        if doc.head?
          @cached_value || @cached_value = doc.store.find($1) || "@##{$1}.#{$2}"
        else
          @cached_value || @cached_value = doc.store.find($1,$2) || "@##{$1}.#{$2}"
        end
      when Hash, Array
        v.map {|v| decode_value(v) }
      else
        v
      end
    end
    
  end
  
end
