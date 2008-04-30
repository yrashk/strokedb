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
  
  module MetaDSL
    def on_initialize(&block)
      store_dsl_options("on_initialize", block)
    end
  end
  
  module HasMany
    attach_dsl MetaDSL
    def has_many(*args)
      store_dsl_options("has_many", { :module => HasMany, :args => args } )
      puts "has_many defined in #{self.inspect}"
    end
    on_initialize do |doc|
      blah_blah
    end
  end
  
  module App1
    attach_dsl HasMany
    has_many :blah, :blah => :blah
    
  end
  
  p App1.dsl
  p App1.dsl["has_many"][:module].dsl
  
end


