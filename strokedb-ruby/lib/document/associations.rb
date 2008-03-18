module StrokeDB

  module Associations

    module HasManyAssociation
      attr_reader :association_owner, :association_slotname
      def new(slots={})
        association_meta.constantize.new(association_owner.store,slots.merge({association_reference_slotname => association_owner}))
      end
      alias :build :new

      def create!(slots={})
        new(slots).save!
      end
      
      def find(query={})
        association_owner._has_many_association(association_slotname,query)
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
        association_owner.meta["has_many_#{association_slotname}"][:meta]
      end

    end

    def has_many(slotname,opts={},&block)
      opts = opts.stringify_keys

      reference_slotname = opts['foreign_reference']
      through = opts['through'] || []
      through = [through] unless through.is_a?(Array)
      meta = (through.shift || slotname).to_s.singularize.camelize
      query = opts['conditions'] || {}

      extend_with = opts['extend'] || block

      @meta_initialization_procs << Proc.new do
        case extend_with
        when Proc
          extend_with_proc = extend_with
          extend_with = "HasMany#{slotname.to_s.camelize}"
          const_set(extend_with,Module.new(&extend_with_proc))
          extend_with = "#{self.name}::HasMany#{slotname.to_s.camelize}"
        when Module
          extend_with = extend_with.name
        when NilClass
        else
          raise "has_many extension should be either Module or Proc"
        end
        reference_slotname = reference_slotname || name.demodulize.tableize.singularize
        if name.index('::') # we're in namespaced meta
          _t = name.split('::')
          _t.pop
          _t << meta
          meta = _t.join('::') 
        end
        @args.last.reverse_merge!({"has_many_#{slotname}" => { :reference_slotname => reference_slotname, :through => through, :meta => meta, :query => query, :extend_with => extend_with } })
        define_method(slotname) do 
          _has_many_association(slotname,{})
        end

      end

    end 

    private 

    def initialize_associations
      define_method(:_has_many_association) do |slotname,additional_query|
        slot_has_many = meta["has_many_#{slotname}"]
        reference_slotname = slot_has_many[:reference_slotname]
        through = slot_has_many[:through]
        meta = slot_has_many[:meta]
        query = slot_has_many[:query]
        effective_query = query.merge(:meta => meta.constantize.document, reference_slotname => self).merge(additional_query)

        result = LazyArray.new.load_with do |lazy_array|
          store.search(effective_query).map do |d| 
            begin
              through.each { |t| d = d.send(t) }
            rescue SlotNotFoundError
              d = nil
            end
            d
          end.compact
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
