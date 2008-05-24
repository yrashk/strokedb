module StrokeDB
  def GenerateAllSlotsView(store)
    View.named(store, "strokedb_all_slots") do |view|
      def view.map(uuid, doc)
        doc.slotnames.inject([]) do |pairs, sname|
          value = doc[sname]
          if value.is_a?(Array)
            value.inject(pairs) do |ps, v|
              ps << [[sname, v], doc]
              ps
            end
          else
            pairs << [[sname, value], doc]
            pairs
          end
        end
      end
    end
  end
end
