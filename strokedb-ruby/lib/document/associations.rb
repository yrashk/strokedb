module StrokeDB

  module Associations
    def has_many(slotname,reference_slotname,query={})
      # @has_many ||= {}
      # @has_many[slotname.to_s] = [reference_slotname.to_s,query]
      # @args.last.reverse_merge!(:has_many => @has_many)
      when_slot_not_found do |doc, missed_slotname|
        # ref_slotname, query = doc.meta[:has_many][slotname]
        doc.store.index_store.find(query).select {|d| d.send(reference_slotname) == doc }  if slotname.to_s == missed_slotname.to_s 
      end
    end 
  end  
end