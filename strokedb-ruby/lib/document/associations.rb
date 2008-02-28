module StrokeDB

  module Associations
    def has_many(slotname,opts={})
      opts = opts.stringify_keys
      reference_slotname = opts['foreign_reference']
      
      through = opts['through'] || []
      through = [through] unless through.is_a?(Array)
      
      meta = (through.shift || slotname).to_s.singularize.camelize
      
      query = opts['conditions'] || {}
      when_slot_not_found do |doc, missed_slotname|
        effective_query = query.merge(:__meta__ => meta.constantize.document)
        effective_reference_slotname = reference_slotname || doc.meta.name.tableize.singularize
        if slotname.to_s == missed_slotname.to_s 
          doc.store.index_store.find(effective_query).select do |d| 
            d[effective_reference_slotname] && d.send(effective_reference_slotname) == doc 
          end.map {|d| through.each {|t| d = d.send(t)  } ; d}
        end
      end
    end 
  end  
end