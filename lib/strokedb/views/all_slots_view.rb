module StrokeDB
  def GenerateAllSlotsView(store)
    View.named(store, "strokedb_all_slots") do |view|
      def view.map(uuid, doc)
        doc.slotnames.inject([]) do |pairs, sname|
          value = doc[sname]
          key_traversal(sname, value, pairs) do |k, v|
            [[k, v, doc], doc]
          end
        end
      end
    end
  end
  
  def key_traversal(key, value, pairs = [], &block)
    case value
    when Array
      value.inject(pairs) do |ps, v|
        key_traversal(key, v, ps, &block)
      end
    when Hash
      value.to_a.inject(pairs) do |ps, kv|
        key_traversal([key, kv[0]], kv[1], ps, &block)
      end
    else
      pairs << yield(key, value)
      pairs
    end
  end
  
end
