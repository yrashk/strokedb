module StrokeDB
  class Operation
    TAGS_TO_OPERATION_CLASSES = {
      "C" => CreateOperation,
      "D" => DeleteOperation,
      "P" => PatchOperation,
      "T" => Transaction
    }
    OPERATION_CLASSES_TO_TAGS = {
      CreateOperation => "C",
      DeleteOperation => "D",
      PatchOperation  => "P",
      Transaction     => "T"
    }
    attr_accessor :timestamp
    def initialize
      if self.class == Operation
        raise AbstractClassInstantiation.new, "Operation is an abstract class. See inherited classes for instantiation."
      end
    end
    def to_raw(custom_raw)
      [ OPERATION_CLASSES_TO_TAGS[self.class], custom_raw ]
    end
    def self.from_raw(store, raw_content)
      tag, custom_raw = raw_content
      TAGS_TO_OPERATION_CLASSES[tag].from_raw(store, custom_raw)
    end
    class AbstractClassInstantiation < Exception; end
  end
end
