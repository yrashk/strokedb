module StrokeDB
  class Slot
    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def value=(v)
      @value = process_value(v)
      @cached_value = v if v.is_a?(Document)
    end

    def value
      case @value
      when /@##{UUID_RE}.#{VERSION_RE}/
        @cached_value || @cached_value = doc.store.find($1,$2) || "@##{$1}.#{$2}"
      when /@##{UUID_RE}/
        @cached_value || @cached_value = doc.store.find($1) || "@##{$1}"
      else
        @value
      end
    end

    def to_json(opts={})
      @value.to_json(opts.merge(:slot_serialization => true))
    end

    def raw_value
      case @value
      when Hash, Array
        @value.map {|v| process_value(v) }
      else
        @value
      end
    end

    private

    def process_value(v)
      case v
      when VersionedDocument
        "@##{v.uuid}.#{v.version}"
      when Document
        "@##{v.uuid}"
      else
        v
      end
    end
  end
end
