require 'diff/lcs'

module StrokeDB
  
  PATCH_REPLACE = 'R'.freeze
  PATCH_PLUS    = '+'.freeze
  PATCH_MINUS   = '-'.freeze
  PATCH_DIFF    = 'D'.freeze

  class SlotDiffStrategy 
    def self.diff(from, to)
      to
    end
  end

  class DefaultSlotDiff < SlotDiffStrategy
    def self.diff(from, to)
      unless from.class == to.class # if value types are not the same
        to # then return new value
      else
        case to
        when /@##{UUID_RE}/, /@##{UUID_RE}.#{VERSION_RE}/
          to
        when Array, String
          ::Diff::LCS.diff(from, to).map do |d|
            d.map do |change|  
              change.to_a 
            end
          end
        when Hash
          ::Diff::LCS.diff(from.sort_by{|e| e.to_s}, to.sort_by{|e| e.to_s}).map do |d|
            d.map do |change|
              [change.to_a.first, {change.to_a.last.first => change.to_a.last.last}]
            end
          end
        else
          to 
        end
      end
    end

    def self.patch(from, patch)
      case from
      when /@##{UUID_RE}/, /@##{UUID_RE}.#{VERSION_RE}/
        patch
      when String, Array
        lcs_patch = patch.map do |d|
          d.map do |change|
            ::Diff::LCS::Change.from_a(change)
          end
        end
        ::Diff::LCS.patch!(from, lcs_patch)
      when Hash
        lcs_patch = patch.map do |d|
          d.map_with_index do |change, index|
            ::Diff::LCS::Change.from_a([change.first, index, [change.last.keys.first, change.last.values.first]])
          end
        end
        diff = ::Diff::LCS.patch!(from.sort_by{|e| e.to_s}, lcs_patch)
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

    on_initialization do |diff|
      diff.added_slots = {} unless diff[:added_slots]
      diff.removed_slots = {} unless diff[:removed_slots]
      diff.updated_slots = {} unless diff[:updated_slots] 
      diff.send!(:compute_diff) if diff.new?
    end

    def different?
      !updated_slots.empty? || !removed_slots.empty? || !added_slots.empty?
    end

    def patch!(document)
      added_slots.each_pair do |addition, value|
        document[addition] = value
      end
      removed_slots.keys.each do |removal|
        document.remove_slot!(removal)
      end
      updated_slots.each_pair do |update, value|
        if sk = strategy_class_for(update)
          document[update] = sk.patch(document[update], value)
        else
          document[update] =value
        end
      end
    end


    protected

    def compute_diff
      additions = to.slotnames - from.slotnames 
      additions.each do |addition|
        self.added_slots[addition] = to[addition]
      end
      removals = from.slotnames - to.slotnames
      removals.each do |removal|
        self.removed_slots[removal] = from[removal]
      end
      updates = (to.slotnames - additions - ['version']).select {|slotname| to[slotname] != from[slotname]}
      updates.each do |update|
        unless sk = strategy_class_for(update)
          self.updated_slots[update] = to[update]
        else
          self.updated_slots[update] = sk.diff(from[update], to[update]) 
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

  end
  
end

require 'sync/diff/default'
require 'sync/diff/string'
require 'sync/diff/array'
require 'sync/diff/hash'