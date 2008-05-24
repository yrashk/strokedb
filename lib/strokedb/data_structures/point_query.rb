module StrokeDB
  # PointQuery is used to perform navigation to a single multidimensinal point.
  # Initializer accepts a hash of slots. Slots may have such value types: 
  #   "string"           scalar string value
  #   3.1415 (numeric)   numeric value
  #   :L                 lowest value
  #   :H                 highest value
  #
  # Example:
  #   PointQuery.new(:meta   => 'Article', 
  #                  :author => 'Oleg Andreev', 
  #                  :date   => :last)
  #
  class PointQuery
    attr_reader :slots

    def initialize(slots)
      @slots = {}
      slots.each do |k, v|
        k = k.meta_uuid if k.is_a?(Module) # quick hack, but PointQuery will be thrown away as soon as we'll have new search system
        @slots[k.to_optimized_raw] = v.to_optimized_raw
      end
    end
  end
end
