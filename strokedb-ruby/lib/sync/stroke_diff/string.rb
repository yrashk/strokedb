module StrokeDB
  class ::String
    def stroke_diff(to)
      return super(to) unless String === to
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
            [PATCH_PLUS,  p[1], p[2]]
          else
            [PATCH_MINUS, p[1], p[2].size]
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
      
      #puts "#{self.inspect}.stroke_patch(#{patch.inspect}) "
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
  end
end
