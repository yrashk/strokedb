module StrokeDB
  module IndexSlots
    
    # Example:
    #   SomeMeta = Meta.new do 
    #     index_slots :a, :b, [:first_name, :last_name]
    #   end
    #
    def index_slots(*args)
      slots = args.map{|a| a.is_a?(Array) ? a.map{|e|e.to_s} : [a.to_s] }
      view_name = "index_slots_for_#{name}:#{nsurl}"
      doc = document # metadocument
      opts = { :only => name, :slots => slots, :doc_meta => doc }
      doc.index_slots_view = View.define!(view_name, opts) do |view|
        def view.map(uuid, doc)
          meta = self['doc_meta']
          slots.each do |sl|
            k = sl.inject([]) do |a, sn|
              a << sn << doc[sn]
            end
            [[meta, k], doc]
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
