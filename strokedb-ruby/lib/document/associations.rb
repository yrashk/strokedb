module StrokeDB

  module Associations
    def has_many(slotname,opts={})
      opts = opts.stringify_keys

      reference_slotname = opts['foreign_reference']
      through = opts['through'] || []
      through = [through] unless through.is_a?(Array)
      meta = (through.shift || slotname).to_s.singularize.camelize
      query = opts['conditions'] || {}

      @has_many ||= {}
      @has_many[slotname.to_s] = { :reference_slotname => reference_slotname, :through => through, :meta => meta, :query => query}
      @args.last.reverse_merge!(:has_many => @has_many)

      when_slot_not_found(:has_many) do |doc, missed_slotname|
        if doc.meta[:has_many] && doc.meta.has_many.is_a?(Hash) && slot_has_many = doc.meta.has_many[missed_slotname.to_s]
          reference_slotname = slot_has_many[:reference_slotname]
          through = slot_has_many[:through]
          meta = slot_has_many[:meta]
          query = slot_has_many[:query]
          effective_query = query.merge(:__meta__ => meta.constantize.document)
          effective_reference_slotname = reference_slotname || doc.meta.name.tableize.singularize
          doc.store.index_store.find(effective_query).select do |d| 
            d[effective_reference_slotname] && d.send(effective_reference_slotname) == doc 
          end.map {|d| through.each {|t| d = d.send(t)  } ; d}
        end
      end
    end 
  end  
end