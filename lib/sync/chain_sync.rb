module StrokeDB
  # You may mix-in this into specific sync implementations
  module ChainSync
    # We have 2 chains as an input: our chain ("to") and 
    # a foreign chain ("from"). We're going to calculate
    # the difference between those chains to know how to
    # implement synchronization.
    #
    # There're two cases:
    # 1) from is a subset of to -> nothing to sync
    # 2) to is a subset of from -> fast-forward merge
    # 3) else: merge case: return base, head_from & head_to
    def sync_chains(from, to)
      common = from & to
      raise NonMatchingChains, "no common element found" if common.empty?
      base = common[common.size - 1]
      ifrom = from.index(base)
      ito   = to.index(base)
      
      # from:  -------------base
      # to:    -----base----head
      if ifrom == from.size - 1
        :up_to_date
      
      # from:  -----base----head
      # to:    -------------base
      elsif ito == to.size - 1
        [ :fast_forward, from[ifrom..-1] ]
      
      # from:  -----base--------head
      # to:    --------base-----head
      else
        [ :merge, from[ifrom..-1], to[ito..-1] ]
      end
    end
    class NonMatchingChains < Exception; end
  end
end
