module Stroke
  class NoDefaultStoreError < Exception ; end
  class SlotNotFoundError < Exception 
    attr_reader :slotname
    def initialize(slotname)
      @slotname = slotname
    end
  end
  
  class StrokeObject < StrokeDB::Document
    def initialize(*args)
      if args.first.is_a?(Hash) || args.empty?
        raise NoDefaultStoreError.new unless Stroke.default_store
        super(Stroke.default_store,*args)
      else
        super(*args)
      end
    end
    def method_missing(sym,*args,&block)
      sym = sym.to_s
      if sym.ends_with?('=')
        send(:[]=,sym.chomp('='),*args)
      else
        raise SlotNotFoundError.new(sym) unless slotnames.include?(sym)
        send(:[],sym)
      end
    end
  end
  class StrokeDB::Store
    private
    def document_class
      StrokeObject
    end
  end
end