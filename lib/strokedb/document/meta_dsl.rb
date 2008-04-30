module StrokeDB
  module MetaDSL
    def on_initialize(&block)
      store_dsl_options("on_initialize", block)
    end
  end
end
