module StrokeDB
  def GenerateAllSlotsView(store)
    View.named(store, "strokedb_all_slots") do |view|
      def view.map(uuid, doc)
        doc.slotnames.inject([]) do |pairs, sname|
          value = doc[sname]
          key_traversal([sname], value, pairs) do |k, v|
            [k + [v, doc], doc]
          end
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
          ax << yield(key, value)
          ax
        end
      end
    end
  end
end
