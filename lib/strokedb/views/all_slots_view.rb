module StrokeDB
  
  MAGIC_ALL_SLOTS_VIEW_SEPARATOR = "47f16bd6-7c22-4f6c-aafb-2e1f121a7f85".freeze
  
  def GenerateAllSlotsView(store)
    View.named(store, "strokedb_all_slots") do |view|
      
      def view.map(uuid, doc)
        doc.slotnames.inject([]) do |pairs, sname|
          value = doc[sname]
          key_traversal([sname], value, pairs) do |k, v|
            [k + [v, MAGIC_ALL_SLOTS_VIEW_SEPARATOR, doc], doc]
          end
        end
      end
      
      def view.search(query)
        key_traversal([], query) do |key, value|
          find(key + [value, MAGIC_ALL_SLOTS_VIEW_SEPARATOR]) 
        end.inject do |set, subset|
          set & subset
        end
      end
      
      def view.key_traversal(key, value, ax = [], &block)
        case value
        when Array
          value.inject(ax) do |bx, v|
            key_traversal(key, v, bx, &block)
          end
        when Hash
          value.to_a.inject(ax) do |bx, kv|
            key_traversal(key + kv[0,1], kv[1], bx, &block)
          end
        else
          ax << yield(key, value.to_s)
          ax
        end
      end
    end
  end
end
