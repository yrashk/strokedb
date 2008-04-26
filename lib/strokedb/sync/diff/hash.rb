module StrokeDB
  class ::Hash
    def stroke_diff(to)
      return super(to) unless to.is_a?(Hash)
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
    
    # Hash conflict may occur:
    # 1) If key accures in conflicting groups 
    #    (e.g. deleted v.s. inserted, deleted vs. diffed)
    # 2) If slot diff yields conflict
    #
    def stroke_merge(patch1, patch2)
      unless patch1 && patch2
        return _stroke_automerged(stroke_patch(patch1 || patch2))
      end
      
      del1, ins1, dif1 = patch1[0].dup, patch1[1].dup, patch1[2].dup
      del2, ins2, dif2 = patch2[0].dup, patch2[1].dup, patch2[2].dup
      
      # TEMPORARY: inconsistency check
      conflict_d1i2 = del1 & ins2.keys
      conflict_d2i1 = del2 & ins1.keys
      conflict_i1f2 = ins1.keys & dif2.keys
      conflict_i2f1 = ins2.keys & dif1.keys
      
      unless conflict_d1i2.empty? && conflict_d2i1.empty? && 
             conflict_i1f2.empty? && conflict_i2f1.empty? 
        raise "Fatal inconsistency on stroke_merge detected!"
      end
      
      overlapping_keys = ((del1 + ins1.keys + dif1.keys) & 
                          (del2 + ins2.keys + dif2.keys))
      # make hash for faster inclusion tests
      overlapping_keys_hash = overlapping_keys.inject({}) do |h, k|
        h[k] = 1; h
      end
      
      result  = self.dup
      
      # 1. Merge non-overlapping updates
      (del1 + del2 - overlapping_keys).each do |k|
        del1.delete(k)
        del2.delete(k)
        result.delete(k)
      end
      ins1.dup.each do |k, v|
        unless overlapping_keys_hash[k]
          result[k] = v 
          ins1.delete(k)
        end
      end
      ins2.dup.each do |k, v|
        unless overlapping_keys_hash[k]
          result[k] = v 
          ins2.delete(k)
        end
      end
      dif1.dup.each do |k, diff|
        unless overlapping_keys_hash[k]
          result[k] = stroke_patch(diff)
          dif1.delete(k)
        end
      end
      dif2.dup.each do |k, diff|
        unless overlapping_keys_hash[k]
          result[k] = stroke_patch(diff)
          dif2.delete(k)
        end
      end
    
      # 2. Resolve overlapping keys
      #
      # Overlapping key may be in such pairs:
      #
      #  [dif, dif] <- possible conflict
      #  [dif, ins] <- anomaly
      #  [ins, ins] <- possible conflict
      #  [del, ins] <- anomaly
      #  [del, dif] <- conflict
      #  [del, del] <- not a conflict
      #
      #  (and in reverse order as well)
      
      result1 = nil
      result2 = nil
      del1.each do |k|
        if ins2.key?(k)
          raise "Fatal inconsistency on stroke_merge detected: delete + insert"
        elsif dif2.key?(k) 
          # Conflict. Split result if not splitted.
          result1, result2, result = _stroke_split_merge_result(result) if result
          result1.delete(k)
          result2[k] = result2[k].stroke_patch(dif2[k])
        else # [del, del]
          if result
            result.delete(k)
          else
            result1.delete(k)
            result2.delete(k)
          end
        end
      end
      dif1.each do |k, diff|
        if ins2.key?(k)
          raise "Fatal inconsistency on stroke_merge detected: diff + insert"
        elsif dif2.key?(k) # possible conflict
          conflict, r1, r2 = self[k].stroke_merge(diff, dif2[k])
          if conflict
            result1, result2, result = _stroke_split_merge_result(result) if result
            result1[k] = r1
            result2[k] = r2
          else
            if result
              result[k] = r2
            else
              result1[k] = r2
              result2[k] = r2
            end
          end
        else # [dif, del] <- conflict
          # Conflict. Split result if not splitted.
          result1, result2, result = _stroke_split_merge_result(result) if result
          result1[k] = result1[k].stroke_patch(diff)
          result2.delete(k)
        end
      end
      ins1.each do |k, obj|
        if ins2.key?(k) # possible conflict
          if obj != ins2[k]
            result1, result2, result = _stroke_split_merge_result(result) if result
            result1[k] = obj
            result2[k] = ins2[k]
          else
            if result
              result[k] = obj
            else
              result1[k] = obj
              result2[k] = obj
            end
          end
        else # delete or diff
          raise "Fatal inconsistency on stroke_merge detected: insert + (delete|diff)"
        end
      end
      
      result ? _stroke_automerged(result) : _stroke_conflicted(result1, result2)
    end
    
    # In case of conflict, result is copied to result{1,2} and nullified.
    def _stroke_split_merge_result(result)
      return [result.dup, result.dup, nil]
    end
  end
end
