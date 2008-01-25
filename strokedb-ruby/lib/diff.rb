require 'diff/lcs'
module StrokeDB
  
  class SlotDiffStrategy 
    def self.diff(from,to)
      to
    end
  end
  
  class DefaultSlotDiff < SlotDiffStrategy
    def self.diff(from,to)
      unless from.class == to.class # if value types are not the same
        to # then return new value
      else
        case to
        when Array, String
          ::Diff::LCS.diff(from,to).map do |d|
              d.map do |change|   
                { :position => change.position,
                  :element => change.element,
                  :action => change.action
                }
              end
          end
        when Hash
          ::Diff::LCS.diff(from.sort_by(&:to_s),to.sort_by(&:to_s)).map do |d|
            d.map do |change|
              {
                :element => { change.element.first => change.element.last} ,
                :action => change.action
              }
            end
          end
        else
          to 
        end
      end
    end
  end
  
  class Diff < Document
    def initialize(store,from,to)
      @from, @to = from, to
      super(store)
      compute_diff
    end
    
    def removed_slots
      find_slots 'dropslot'
    end    

    def added_slots
      find_slots 'addslot'
    end    
    
    def updated_slots
      find_slots 'updateslot'
    end
    
    protected
    
    def compute_diff
      additions = @to.slotnames - @from.slotnames 
      additions.each do |addition|
        self["__diff_addslot_#{addition}__"] = @to[addition]
      end
      removals = @from.slotnames - @to.slotnames
      removals.each do |removal|
        self["__diff_dropslot_#{removal}__"] = @from[removal]
      end
      updates = (@to.slotnames - additions - ['__version__']).select {|slotname| @to[slotname] != @from[slotname]}
      updates.each do |update|
        self["__diff_updateslot_#{update}__"] = @to[update]
        if @from[:__meta__] && strategy = @from[:__meta__]["__diff_strategy_#{update}__"]
          strategy_class = strategy.camelize.constantize rescue nil
          if strategy_class && strategy_class.ancestors.include?(SlotDiffStrategy)
            self["__diff_updateslot_#{update}__"] = strategy_class.diff(@from[update],@to[update]) 
          end
        end
      end
    end

    module SlotAccessor
      def [](name)
        return at(name) if name.is_a?(Numeric)
        @diff["__diff_#{@keyword}_#{name}__"]
      end
    end
    
    def find_slots(keyword)
      re = /^__diff_#{keyword}_(.+)__$/
      slots = slotnames.select {|slotname| slotname.match(re)}.map{|slotname| slotname.gsub(re,'\\1') }
      slots.extend(SlotAccessor)
      slots.instance_variable_set(:@diff,self)
      slots.instance_variable_set(:@keyword,keyword)
      slots
    end
    
  end
end