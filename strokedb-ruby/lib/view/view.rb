module StrokeDB
  View = Meta.new do
    attr_accessor :map_with_proc
    on_meta_initialization do |view, block|
      view.map_with_proc = block
    end
    
    def reduce_with(&block)
      @reduce_with_block = block
      self
    end

    def documents(*args) 
      mapped = @map_with_proc ? store.map {|doc| map_with_proc.call(doc,*args) } : store.collect{|d| d }
      @reduce_with_block ? mapped.select(&@reduce_with_block) : mapped
    end
  end
end