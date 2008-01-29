module StrokeDB
  class Slot
    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def value=(v)
      case v
      when VersionedDocument
        @value = "@##{v.uuid}.#{v.version}"
        @cached_value = v # lets cache it locally
      when Document
        @value = "@##{v.uuid}"
        @cached_value = v # lets cache it locally
      else
        @value = v
      end
    end

    def value
      case @value
      when /@##{UUID_RE}.#{VERSION_RE}/
        doc.store.find($1,$2) || @cached_value || "@##{$1}.#{$2}"
      when /@##{UUID_RE}/
        doc.store.find($1) || @cached_value || "@##{$1}"
      else
        @value
      end
    end

    def to_json(opts={})
      @value.to_json(opts.merge(:slot_serialization => true))
    end
    
    def raw_value
      @value
    end
  end
end
