module StrokeDB

  module Associations
    def has_many(slotname,opts={})
      opts = opts.stringify_keys
      reference_slotname = opts['foreign_reference']
      meta = opts['with_meta'] || slotname.to_s.singularize
      meta = meta.camelize
      query = opts['conditions'] || {}
      when_slot_not_found do |doc, missed_slotname|
        effective_query = query.merge(:__meta__ => meta.constantize.document)
        effective_reference_slotname = reference_slotname || doc.meta.name.tableize.singularize
        doc.store.index_store.find(effective_query).select {|d| d.send(effective_reference_slotname) == doc }  if slotname.to_s == missed_slotname.to_s 
      end
    end 
  end  
end