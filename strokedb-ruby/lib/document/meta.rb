module StrokeDB

  class Callback
    attr_reader :origin
    def initialize(origin,&block)
      @origin, @block = origin, block
    end
    def call(*args)
      @block.call(*args)
    end
  end

  module Meta

    class << self
      def new(*args,&block)
        mod = Module.new
        args = args.unshift(nil) if args.empty? || args.first.is_a?(Hash) 
        args << {} unless args.last.is_a?(Hash)
        mod.module_eval do
          extend Meta
          extend Associations
          @args = args
        end
        mod.module_eval(&block) if block_given?
        if meta_name = extract_meta_name(*args)
          Object.const_set(meta_name,mod)
        end
        mod
      end

      def document(store=nil)
        store ||= StrokeDB.default_store
        raise NoDefaultStoreError.new unless store
        unless meta_doc = store.find(NIL_UUID)
          meta_doc = Document.new(store,:name => Meta.name)
          meta_doc.instance_variable_set(:@uuid,NIL_UUID) # hack that ensures that meta meta is uniquely identified by nil uuid
          meta_doc.save!
        end
        meta_doc
      end


      private

      def extract_meta_name(*args)
        if args.first.is_a?(Hash) 
          args.first[:name]
        else
          args[1][:name] unless args.empty?
        end
      end


    end

    CALLBACKS = %w(on_initialization before_save after_save when_slot_not_found)
    CALLBACKS.each do |callback_name|
      module_eval %{
        def #{callback_name}(&block)
          add_callback('#{callback_name}',&block)
        end
      }
    end

    def new(*args,&block)
      doc = Document.new(*args,&block)
      doc.extend(self)
      doc[:__meta__] = document(doc.store)
      setup_callbacks(doc)
      doc.send(:execute_callbacks,:on_initialization)
      doc
    end

    def create!(*args,&block)
      new(*args,&block).save!
    end

    def find(*args)
      args = args.unshift(StrokeDB.default_store) if args.empty? || args.first.is_a?(Hash) 
      args << {} unless args.last.is_a?(Hash)
      store = args.first
      raise NoDefaultStoreError.new unless StrokeDB.default_store
      store.index_store.find(args.last.merge(:__meta__ => document(store)))
    end

    def find_or_create(*args)
      result = find(*args)
      result.empty? ? create!(*args) : result.first
    end

    def inspect
      "{#{name}#{is_a?(Module) ? ' meta module' : ''}}"
    end
    alias :to_s :inspect


    def document(store=nil)
      store ||= StrokeDB.default_store
      raise NoDefaultStoreError.new unless store
      args = @args.clone
      args[0] = store
      args.last[:__meta__] = Meta.document(store)
      args.last[:name] ||= name
      unless meta_doc = (store.respond_to?(:index_store) && store.index_store) ? store.index_store.find(:name => args.last[:name], 
        :__meta__ => Meta.document(store)).first : nil
        meta_doc = Document.new(*args)
        meta_doc.extend(Meta)
        meta_doc.save!
      else
        args.last[:__version__] = meta_doc.__version__
        unless (new_doc = Document.new(*args)).to_raw == meta_doc.to_raw
          meta_doc.slotnames.each {|slotname| meta_doc.remove_slot!(slotname) }
          new_doc.slotnames.each {|slotname| meta_doc[slotname] = new_doc[slotname]}
          meta_doc.save!
        end
      end
      meta_doc
    end

    private

    def add_callback(name,&block)
      @callbacks ||= {}
      @callbacks[name] ||= []
      @callbacks[name] << block
    end
    
    def setup_callbacks(doc)
      return unless @callbacks
      @callbacks.each_pair do |callback_name, blocks|
        blocks.each do |block|
          callback = Callback.new(self,&block)
          doc.callbacks[callback_name] ||= []
          doc.callbacks[callback_name] << callback
        end
      end
    end
    
  end

end

