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
        when /@##{UUID_RE}/
          to
        when Array, String
          ::Diff::LCS.diff(from,to).map do |d|
            d.map do |change|  
              change.to_a 
            end
          end
        when Hash
          ::Diff::LCS.diff(from.sort_by(&:to_s),to.sort_by(&:to_s)).map do |d|
            d.map do |change|
              [change.to_a.first,{change.to_a.last.first => change.to_a.last.last}]
            end
          end
        else
          to 
        end
      end
    end

    def self.patch(from,patch)
      case from
      when /@##{UUID_RE}/
        patch
      when String, Array
        lcs_patch = patch.map do |d|
          d.map do |change|
            ::Diff::LCS::Change.from_a(change)
          end
        end
        ::Diff::LCS.patch!(from,lcs_patch)
      when Hash
        lcs_patch = patch.map do |d|
          d.map_with_index do |change,index|
            ::Diff::LCS::Change.from_a([change.first,index,[change.last.keys.first,change.last.values.first]])
          end
        end
        diff = ::Diff::LCS.patch!(from.sort_by(&:to_s),lcs_patch)
        hash = {}
        diff.each do |v|
          hash[v.first] = v.last
        end
        hash
      else
        patch
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