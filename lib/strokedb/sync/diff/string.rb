module StrokeDB
  class ::String
    def stroke_diff(to)
      return super(to) unless to.is_a?(String)
      return nil if self == to
      
      _f = self[0,2]
      _t = to[0,2]
      pfx = "@#"
      # both are refs
      return super(to) if _f == _t && _t == pfx
      # one of items is ref, another is not.
      return super(to) if _f == pfx || _t == pfx
            
      lcs_diff = ::Diff::LCS.diff(self, to)
      patchset = lcs_diff.map do |changes| 
        parts = []
        last_part = changes.inject(nil) do |part, change|
          if part && part[0] == change.action && part[3] == change.position - 1
            part[3] += 1
            part[2] << change.element
            part
          else
            parts << part if part
            # emit
            [change.action, change.position, change.element, change.position]
          end
        end
        parts << last_part if last_part
        parts.empty? ? nil : parts
      end.compact.inject([]) do |patches, ps|
        ps.map do |p|
          patches << if p[0] == '+'
            [PATCH_PLUS,  p[1], p[2]]      # [+  position_in_b  substr]
          else
            [PATCH_MINUS, p[1], p[2].size] # [-  position_in_a  length]
          end
        end
        patches
      end
      #p patchset
      patchset.empty? ? nil : patchset
    end
    
    def stroke_patch(patch)
      return self unless patch
      return patch[1] if patch[0] == PATCH_REPLACE
      
      # Patch is a list of insertions and deletions.
      # Deletion is indexed relative to base.
      # Insertion is indexed relative to new string.
      res = ""
      ai = bj = 0
      patch.each do |change|
        action, position, element = change
        case action
        when PATCH_MINUS
          d = position - ai
          if d > 0
            res << self[ai, d]
            ai += d
            bj += d
          end
          ai += element # element == length
        when PATCH_PLUS
          d = position - bj
          if d > 0
            res << self[ai, d]
            ai += d
            bj += d
          end
          bj += element.size
          res << element
        end
      end
      d = self.size - ai
      res << self[ai, d] if d > 0
      res
    end
    
    def stroke_merge(patch1, patch2)
      # One patch is missing (i.e. no changes)
      unless patch1 && patch2
        return _stroke_automerged(stroke_patch(patch1 || patch2))
      end

      # Patch could be either PATCH_REPLACE or regular string diff.
      # Thus, 4 cases:
      #
      # [replace, replace] -> possible conflict
      # [replace, diff]    -> conflict
      # [diff,    replace] -> conflict
      # [diff,    diff]    -> possible conflict

      # Code is verbose to be fast and clear
      if patch1[0] == PATCH_REPLACE
        if patch2[0] == PATCH_REPLACE # [replace, replace]
          if patch1[1] != patch2[1]
            return _stroke_conflicted(stroke_patch(patch1), stroke_patch(patch2))
          else
            return _stroke_automerged(stroke_patch(patch1))
          end
        else # [replace, diff]
           return _stroke_conflicted(stroke_patch(patch1), stroke_patch(patch2))
        end
      else
        if patch1[0] == PATCH_REPLACE # [diff, replace]
          return _stroke_conflicted(stroke_patch(patch1), stroke_patch(patch2))
        else
          nil # [diff, diff] - see below
        end
      end
	  # TODO: ...
    end
  end
end
