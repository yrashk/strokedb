module StrokeDB
  class Transaction < Operation
    attr_accessor :uuid, :transaction_document
    def initialize(doc)
      super
      @uuid                 = doc.uuid
      @transaction_document = doc
    end
    def to_raw
      super([@uuid, @transaction_document.to_raw])
    end
    def self.from_raw(store, raw_content)
      new(Document.from_raw(store, raw_content[0], raw_content[1]))
    end
  end
end
