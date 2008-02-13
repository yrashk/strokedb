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
        when /@##{UUID_RE}/, /@##{UUID_RE}.#{VERSION_RE}/
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
      when /@##{UUID_RE}/, /@##{UUID_RE}.#{VERSION_RE}/
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

  Diff = Meta.new do

    on_initialization do |diff, block|
      diff.send!(:compute_diff) if diff.new?
    end

    def removed_slots
      find_slots 'drop_slot'
    end    

    def added_slots
      find_slots 'add_slot'
    end    

    def updated_slots
      find_slots 'update_slot'
    end

    def different?
      !updated_slots.empty? || !removed_slots.empty? || !added_slots.empty?
    end

    def patch!(document)
      added_slots.each do |addition|
        document[addition] = added_slots[addition]
      end
      removed_slots.each do |removal|
        document.remove_slot!(removal)
      end
      updated_slots.each do |update|
        if sk = strategy_class_for(update)
          document[update] = sk.patch(document[update],updated_slots[update])
        else
          document[update] = updated_slots[update]
        end
      end
    end


    protected

    def compute_diff
      additions = to.slotnames - from.slotnames 
      additions.each do |addition|
        self["add_slot_#{addition}"] = to[addition]
      end
      removals = from.slotnames - to.slotnames
      removals.each do |removal|
        self["drop_slot_#{removal}"] = from[removal]
      end
      updates = (to.slotnames - additions - ['__version__']).select {|slotname| to[slotname] != from[slotname]}
      updates.each do |update|
        unless sk = strategy_class_for(update)
          self["update_slot_#{update}"] = to[update]
        else
          self["update_slot_#{update}"] = sk.diff(from[update],to[update]) 
        end
      end
    end

    def strategy_class_for(slotname)
      if from.meta && strategy = from.meta["diff_strategy_#{slotname}"]
        _strategy_class = strategy.camelize.constantize rescue nil
        return _strategy_class if _strategy_class && _strategy_class.ancestors.include?(SlotDiffStrategy)
      end
      false
    end

    module SlotAccessor
      def [](name)
        return at(name) if name.is_a?(Numeric)
        @diff["#{@keyword}_#{name}"]
      end
      def clear!
        @diff.slotnames.each do |slotname|
          @diff.remove_slot!(slotname) if slotname.match(/^#{@keyword}_(.+)$/)
        end
      end
    end

    def find_slots(keyword)
      re = /^#{keyword}_(.+)$/
      slots = slotnames.select {|slotname| slotname.match(re)}.map{|slotname| slotname.gsub(re,'\\1') }
      slots.extend(SlotAccessor)
      slots.instance_variable_set(:@diff,self)
      slots.instance_variable_set(:@keyword,keyword)
      slots
    end

  end
  
end