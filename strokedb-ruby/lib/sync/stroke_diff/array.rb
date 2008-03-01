module StrokeDB
  class ::Array
    SDATPTAGS = {
      '-' => PATCH_MINUS,
      '+' => PATCH_PLUS,
      '!' => PATCH_DIFF
    }.freeze
    def stroke_diff(to)
      return super(to) unless Array === to
      return nil if self == to
      
      # sdiff:  +   -   !   = 
      lcs_sdiff = ::Diff::LCS.sdiff(self, to)
      patchset = lcs_sdiff.inject([]) do |patchset, change|
        a = SDATPTAGS[change.action]
        if a == PATCH_DIFF
          # patchset << [a, change.old_position, change.new_position, 
          #                 change.old_element.stroke_diff(change.new_element)]
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
      # Version 2
      res = self.dup
      patch.each do |change|
        case change[0]
        when PATCH_MINUS
          action, position = change
          res.delete_at(position)
        when PATCH_PLUS
          action, position, element = change
          res[position, 0] = [element]
        when PATCH_DIFF
          action, position, diff = change
          res[position] = res[position].stroke_patch(diff)
        end
      end
      res
    end
    
    
    def stroke_merge(patch1, patch2)
      
      
      
    end
    
  end
end
