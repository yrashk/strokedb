module StrokeDB
  
  ByMetas = View.new "strokedb_all_docs_by_metas" do |view|
    def view.map(uuid, doc)
      doc.metas.each do |meta|
        
      end
    end
  end
  
end
