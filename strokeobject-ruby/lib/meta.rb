module Stroke
  module MetaDefinition
    def new(*args)
      doc = StrokeObject.new(*args)
      doc.extend(self)
      doc[:__meta__] = meta(doc.store)
      doc
    end
    private
    def meta(store)
      @meta ||= StrokeDB::Document.new(store, :name => name) # FIXME: it is just a stub for future meta-related undercover
    end
  end
end

module Kernel
  def define_meta(name,&block)
    mod = Module.new do
      extend Stroke::MetaDefinition
    end
    mod.module_eval(&block) if block_given?
    Object.const_set(name,mod)
    name.to_s.constantize
  end
end
