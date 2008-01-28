module StrokeDB
  class RangeQuery
    attr_reader :ranges,          # :key => .., :key2 => ..
                :order_by,        # :key
                :reversed_order,  # true/false
                :limit,
                :offset
    
    def initialize(ranges, options = {})
      @order_by       = options.delete(:order_by)
      @reversed_order = options.delete(:reversed_order)
      @limit          = options.delete(:limit)
      @offset         = options.delete(:offset)
      raise ":reversed_order, :limit and :offset are not supported!" if @reversed_order || @limit || @offset
      
      # Convert single values to ranges
      ranges.each do |d, v| 
        # Prefix string query: {:name => "Oleg A*"} (matches Andreev, Anderson)
        if String === v && v[-1,1] == '*'
          ranges[d] = [v[0..-2], v[0..-2] + "\xff\xff\xff"]
        else
          # Make range from scalar values ("Lisbon" => ["Lisbon", "Lisbon"])
          ranges[d] = [v, v] if (String === v) || !(Enumerable === v)
        end
      end
      ranges[order_by] ||= [ nil, nil ] if order_by
      @ranges = ranges
    end
  end
end
