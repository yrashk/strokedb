module StrokeDB
  class ::Module
    
    # Attach module as DSL. Module may use store_dsl_options 
    # method to store DSL.
    #
    def attach_dsl(mod)
      extend(mod)
      @dsl_options ||= {}
    end
    
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

if $0 == __FILE__
  module HasMany
    def has_many(*args)
      store_dsl_options("has_many", args)
      puts "has_many defined."
    end
  end
  
  module App1
    attach_dsl HasMany
    has_many :blah, :blah => :blah
    
  end
  
  p App1.dsl
  
end


