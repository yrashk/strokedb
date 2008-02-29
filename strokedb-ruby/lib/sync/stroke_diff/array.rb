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
          patchset << [a, change.old_position, change.new_position, 
                          change.old_element.stroke_diff(change.new_element)]
        elsif a == PATCH_MINUS
          patchset << [a, change.old_position]
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
      #puts "#{self.inspect}.stroke_patch(#{patch.inspect}) "
      res = []
      ai = bj = 0
      patch.each do |change|
        case change[0]
        when PATCH_MINUS
          action, position = change
          d = position - ai
          if d > 0
            res += self[ai, d]
            ai += d
            bj += d
          end
          ai += 1
        when PATCH_PLUS
          action, position, element = change
          d = position - bj
          if d > 0
            res += self[ai, d]
            ai += d
            bj += d
          end
          bj += 1
          res << element
        when PATCH_DIFF
          action, pa, pb, diff = change
          da = pa - ai
          db = pb - bj
          raise "Distances do not match!" if da != db
          if da > 0
            res += self[ai, da]
            ai += da
            bj += db
          end
          res << self[ai].stroke_patch(diff)
          ai += 1
          bj += 1
        end
      end
      d = self.size - ai
      res += self[ai, d] if d > 0
      res
    end
    
    
    def stroke_merge(patch1, patch2)
      
      
      
    end
    
  end
end
