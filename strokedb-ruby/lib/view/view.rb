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

    def documents(*args) 
      mapped = store.map {|doc| map_with_proc.call(doc,*args) } 
      @reduce_with_block ? mapped.select {|doc| @reduce_with_block.call(doc,*args) } : mapped
    end
  end
end