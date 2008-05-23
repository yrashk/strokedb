module StrokeDB
  
  ByMetas = View.named "strokedb_all_docs_by_metas" do |view|
    def view.map(uuid, doc)
      doc.metas.map do |meta|
        [meta, doc]
      end
    end
  end
  
end
