module StrokeDB
  class CreateOperation < Operation
    attr_accessor :uuid, :document
    def initialize(doc)
      super
      @uuid     = doc.uuid
      @document = doc
    end
    def to_raw
      super([@uuid, @document.to_raw])
    end
    def self.from_raw(store, raw_content)
      new(Document.from_raw(store, raw_content[0], raw_content[1]))
    end
  end
end
