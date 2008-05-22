module StrokeDB

  module Associations
    
    AssociationViewImplementation = Proc.new do |view|
      def view.map(uuid, doc)
        reference_slotname = self[:reference_slotname]
        through = self[:through]
        expected_meta = self[:expected_meta]
        expected_nsurl = self[:expected_nsurl]
        conditions = self[:conditions]
        sort_by = self[:sort_by]

        if doc.meta.name == expected_meta && doc.meta.nsurl == expected_nsurl
          if (reference_slotname_value = doc[reference_slotname]) &&
             (conditions.nil? ||
              (conditions &&
               (conditions.keys.select {|k| doc[k] == conditions[k]}.size == conditions.size)))
            begin
              key = [reference_slotname_value, doc]
              key = [key[0],doc.send(sort_by),key[1]] if sort_by
              through.each {|t| doc = doc.send(t) }
            rescue SlotNotFoundError
              return nil unless doc
            else
              [ 
                [
                  key,
                  doc
                ]
              ]
            end
        end
      end
      end
    end

    module HasManyAssociation
      attr_reader :association_owner, :association_slotname
      def new(slots={})
        association_meta.constantize.new(association_owner.store, slots.merge({association_reference_slotname => association_owner}))
      end
      alias :build :new

      def create!(slots={})
        new(slots).save!
      end
      
      def <<(doc)
        doc.update_slots! association_reference_slotname => association_owner
        self
      end
      
      private 

      def association_reference_slotname
        association_owner.meta["has_many_#{association_slotname}"][:reference_slotname]
      end

      def association_meta
        association_owner.meta["has_many_#{association_slotname}"][:expected_meta]
      end

    end

    def has_many(slotname, opts={}, &block)
      opts = opts.stringify_keys

      reference_slotname = opts['foreign_reference']
      through = opts['through'] || []
      through = [through] unless through.is_a?(Array)
      meta = (through.shift || slotname).to_s.singularize.camelize
      nsurl = opts['nsurl'] || (name.modulize.empty? ? Module.nsurl : meta.modulize.constantize.nsurl)
      extend_with = opts['extend'] || block
      conditions = opts['conditions']
      sort_by = opts['sort_by']
      reverse = opts['reverse'] || false
      
      @meta_initialization_procs << Proc.new do
        case extend_with
        when Proc
          extend_with_proc = extend_with
          extend_with = "HasMany#{slotname.to_s.camelize}"
          const_set(extend_with, Module.new(&extend_with_proc))
          extend_with = "#{self.name}::HasMany#{slotname.to_s.camelize}"
        when Module
          extend_with = extend_with.name
        when NilClass
        else
          raise "has_many extension should be either Module or Proc"
        end
        reference_slotname = reference_slotname || name.demodulize.tableize.singularize
        
        # TODO: remove the below commented out code, it seems that we do not need it anymore
        # (but I am not sure, so that's why I've left it here)
        # if name.index('::') # we're in namespaced meta
        #   _t = name.split('::')
        #   _t.pop
        #   _t << meta
        #   meta = _t.join('::') 
        # end
        
        view = View.named("#{name.modulize.empty? ? Module.nsurl : name.modulize.constantize.nsurl}##{name.demodulize.tableize.singularize}_has_many_#{slotname}",
                                { :reference_slotname => reference_slotname, :through => through, :expected_meta => meta, :expected_nsurl => nsurl, :extend_with => extend_with, 
                                :conditions => conditions, :sort_by => sort_by, :reverse => reverse }, &AssociationViewImplementation)
        
        @args.last.reverse_merge!({"has_many_#{slotname}" => view})
        define_method(slotname) do 
          _has_many_association(slotname)
        end

      end

    end 

    private 

    def initialize_associations
      define_method(:_has_many_association) do |slotname|
        slot_has_many = meta["has_many_#{slotname}"]
        result = LazyArray.new.load_with do |lazy_array|
          slot_has_many.find(:key => self, :reverse => slot_has_many[:reverse])
        end
        if extend_with = slot_has_many[:extend_with] 
          result.extend(extend_with.constantize) 
        end
        result.instance_variable_set(:@association_owner, self)
        result.instance_variable_set(:@association_slotname, slotname)
        result.extend(HasManyAssociation)
        result
      end
    end
  end
end  
