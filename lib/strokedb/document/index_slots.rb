module StrokeDB
  module IndexSlots
    
    # Example:
    #   SomeMeta = Meta.new do 
    #     index_slots :a, :b, [:first_name, :last_name]
    #   end
    #
    def index_slots(*args)
      # Wrap all slots into an array:
      # [:a, :b, [:x, :y]]  => [ [:a], [:b], [:x, :y] ]
      slots = args.map{|a| a.is_a?(Array) ? a.map{|e|e.to_s} : [a.to_s] }
      
      @meta_initialization_procs << Proc.new do
        view_name = "index_slots_for_#{name}:#{nsurl}"
        opts = { :only => name, :slots => slots, :doc_meta => doc }
        doc.index_slots_view = View.define!(view_name, opts) do |view|
          def view.map(uuid, doc)
            meta = self['doc_meta']
            slots.map do |sl|
              # construct a key out of the list of slots
              k = sl.inject([]) do |a, sn|
                # push [slot_name, slot_value]
                a << sn << doc[sn]
              end
              [[meta, k], doc]
            end
          end
        end
      end
    end
    alias :index_slot :index_slots
    
    private
    def initialize_index_slots
      # empty
    end
    
  end
end


