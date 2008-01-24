module StrokeDB
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
      end
    end
    
    def find_slots(keyword)
      slotnames.select {|slotname| slotname.match(/^__diff_#{keyword}_(.+)__$/)}.map{|slotname| slotname.gsub(/^__diff_#{keyword}_(.+)__$/,'\\1') }
    end
    
  end
end