module StrokeDB
  View = Meta.new do
    attr_accessor :map_with_proc
    on_meta_initialization do |view, block|
      view.map_with_proc = block || proc {|doc, *args| doc }
    end
    
    def reduce_with(&block)
      @reduce_with_block = block
      self
    end

    def emit(*args) 
      mapped = store.map {|doc| map_with_proc.call(doc,*args) } 
      Cut.new(store, :documents => (@reduce_with_block ? mapped.select {|doc| @reduce_with_block.call(doc,*args) } : mapped),
                     :view => self,
                     :args => args)
    end
    
    Cut = Meta.new do
      def to_a
        documents
      end
    end
    
  end
end