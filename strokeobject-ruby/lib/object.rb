module Stroke
  class NoDefaultStoreError < Exception ; end
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
        send(:[],sym)
      end
    end
  end
end