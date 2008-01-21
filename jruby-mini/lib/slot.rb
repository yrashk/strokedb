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
        doc.store.find($1) || @cached_value || "@##{$1}"
      else
        @value
      end
    end

    def to_json(opts={})
      @value.to_json(opts)
    end
  end
end
