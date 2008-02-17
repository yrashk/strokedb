module StrokeDB
  class ::Object
    def stroke_diff(to)
      self == to ? nil : [PATCH_REPLACE, to]
    end
    def stroke_patch(patch)
      patch ? patch[1] : self
    end
  end
end
