module StrokeDB
  class Operation

    class << self
      def tags_to_operation_classes
         @tags_to_operation_classes ||= Hash[*subclasses.map{|classname| [(kl=classname.constantize).code, kl]  }.flatten]
      end
      def operation_classes_to_tags
        @operation_classes_to_tags ||= Hash[*subclasses.map{|classname| [kl=classname.constantize, kl.code]  }.flatten]
      end
      def inherited(subclass)
        @tags_to_operation_classes, @operation_classes_to_tags = nil, nil
      end
    end
    attr_accessor :timestamp
    def initialize
      if self.class == Operation
        raise AbstractClassInstantiation.new, "Operation is an abstract class. See inherited classes for instantiation."
      end
    end
    def to_raw(custom_raw)
      [ operation_classes_to_tags[self.class], custom_raw ]
    end
    def self.from_raw(store, raw_content)
      tag, custom_raw = raw_content
      tags_to_operation_classes[tag].from_raw(store, custom_raw)
    end
    class AbstractClassInstantiation < Exception; end
  end
end
