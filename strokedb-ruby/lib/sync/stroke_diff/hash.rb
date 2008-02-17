module StrokeDB
  class ::Hash
    def stroke_diff(to)
      return super(to) unless Hash === to
      return nil if self == to
      
      all_keys = self.keys | to.keys
      
      deleted_slots  = []
      inserted_slots = {}
      diffed_slots   = {}
      
      all_keys.each do |k|
        unless to.key?(k)
          deleted_slots << k
        else
          unless self.key?(k)
            inserted_slots[k] = to[k] 
          else
            diff = self[k].stroke_diff(to[k]) 
            diffed_slots[k] = diff if diff
          end
        end
      end
      [deleted_slots, inserted_slots, diffed_slots]
    end
    
    def stroke_patch(patch)
      return self unless patch
      return patch[1] if patch[0] == PATCH_REPLACE
      res = self.dup
      deleted_slots, inserted_slots, diffed_slots = patch
      deleted_slots.each {|k| res.delete(k) }
      res.merge!(inserted_slots)
      diffed_slots.each {|k,v| res[k] = self[k].stroke_patch(v) }
      res
    end
  end
end
