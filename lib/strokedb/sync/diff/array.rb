module StrokeDB
  class ::Array
    SDATPTAGS = {
      '-' => PATCH_MINUS,
      '+' => PATCH_PLUS,
      '!' => PATCH_DIFF
    }.freeze
    def stroke_diff(to)
      return super(to) unless to.is_a?(Array)
      return nil if self == to
      
      # sdiff:  +   -   !   = 
      lcs_sdiff = ::Diff::LCS.sdiff(self, to)
      patchset = lcs_sdiff.inject([]) do |patchset, change|
        a = SDATPTAGS[change.action]
        if a == PATCH_DIFF
          patchset << [a, change.new_position, change.old_element.stroke_diff(change.new_element)]
        elsif a == PATCH_MINUS
          patchset << [a, change.new_position]
        elsif a == PATCH_PLUS
          patchset << [a, change.new_position, change.new_element]
        end
        patchset
      end
      patchset.empty? ? nil : patchset
    end
    
    def stroke_patch(patch)
      return self unless patch
      return patch[1] if patch[0] == PATCH_REPLACE
      res = self.dup
      patch.each do |change|
        _stroke_elementary_patch(res, change[1], change)
      end
      res
    end
    
    def stroke_merge(patch1, patch2)
      unless patch1 && patch2
        return _stroke_automerged(stroke_patch(patch1 || patch2))
      end
      
      patch1 = patch1.dup
      patch2 = patch2.dup
      
      c1 = patch1.shift
      c2 = patch2.shift
      
      offset1 = 0
      offset2 = 0
      result = self.dup
      result1 = nil
      result2 = nil
      
      while c1 && c2
        while c1 && (p1 = c1[1] + offset1) && (p2 = c2[1] + offset2) && p1 < p2
          offset2 += _stroke_elementary_patch(result, p1, c1)
          c1 = patch1.shift
        end
        
        if p1 == p2
          raise "TODO conflict resolution!"
          
          c1 = patch1.shift
        end
        
        while c1 && c2 && (p1 = c1[1] + offset1) && (p2 = c2[1] + offset2) && p2 < p1
          offset1 += _stroke_elementary_patch(result, p2, c2)
          c2 = patch2.shift
        end
      end

      # Tail (one of two) 
      while c1
        offset2 += _stroke_elementary_patch(result, c1[1] + offset1, c1)
        c1 = patch1.shift
      end
      while c2
        offset1 += _stroke_elementary_patch(result, c2[1] + offset2, c2)
        c2 = patch2.shift
      end
      result ? _stroke_automerged(result) : _stroke_conflicted(result1, result2)
    end
    
  private
    def _stroke_elementary_patch(result, pos, change)
      a = change[0]
      case a
      when PATCH_MINUS
        result.delete_at(pos)
        -1
      when PATCH_PLUS
        result[pos, 0] = [change[2]]
        +1
      when PATCH_DIFF
        result[pos] = result[pos].stroke_patch(change[2])
        0
      end
    end
      
  end
end
