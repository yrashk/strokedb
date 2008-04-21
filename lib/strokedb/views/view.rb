module StrokeDB
  View = Meta.new do 
    on_initialization do |view|
      view.instance_variable_get(:@initialization_block).call(view)
    end
  end
end


