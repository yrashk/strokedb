module StrokeDB
  class ::Module
    
    # Attach module as DSL. Module may use store_dsl_options 
    # method to store DSL.
    #
    def attach_dsl(*mods)
      @dsl_options ||= {}
      mods.each do |mod|
        extend(mod)
      end
    end
    alias :attach_dsls :attach_dsl
    
    # Store some data associated with a DSL name.
    #
    def store_dsl_options(name, opts)
      @dsl_options[name] = opts
    end
    
    # Return a map of registered DSLs.
    #
    def dsl
      @dsl_options
    end
  end
end


