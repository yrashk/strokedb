module StrokeDB
  class ::Object
    def stroke_diff(to)
      self == to ? nil : [PATCH_REPLACE, to]
    end
    def stroke_patch(patch)
      patch ? patch[1] : self
    end
    def stroke_merge(patch1, patch2) # => is_conflict, result1, result2
      r1 = self.stroke_patch(patch1)
      r2 = self.stroke_patch(patch2)
      [r1 != r2, r1, r2]
    end
    def _stroke_automerged(r)
      [false, r, r]
    end
    def _stroke_conflicted(r1, r2)
      [true, r1, r2]
    end
  end
end
