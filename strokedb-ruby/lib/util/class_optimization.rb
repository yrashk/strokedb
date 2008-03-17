module StrokeDB
  class ::Class
    # Declare which methods are optimized for particular language. 
    # It is assumed, that optimized version of a method is called
    # <tt>method_name_(language name)</tt>
    #
    # Example: 
    #
    #    # assume, there're methods find_InlineC and insert_InlineC
    #    declare_optimized_methods(:InlineC, :find, :insert)</tt>
    #
    def declare_optimized_methods(lang, *meths)
      meths.flatten!
      @optimized_methods ||= {}
      @optimized_methods[lang.to_s] = meths
      extend ClassOptimization::ClassMethods
    end
    
    # Returns a list of optimized methods for a given language.
    # If no language given, a Hash is returned where key is a language name.
    #
    def optimized_methods(lang = nil)
      @optimized_methods ||= {}
      return @optimized_methods unless lang 
      @optimized_methods[lang.to_s]
    end
  end
  module ClassOptimization
    module ClassMethods
      # Switches methods into optimized versions as declared in
      # <tt>declare_optimized_methods</tt>.
      # Pure ruby methods are always accessible with suffix _PureRuby.
      #
      def optimize!(lang)
        optimized_methods(lang).each do |meth|
          alias_method(:"#{meth}_PureRuby", :"#{meth}")
          alias_method(:"#{meth}",          :"#{meth}_#{lang}")
        end
      end
      
      # Reverts method optimization done with <tt>optimize!</tt>
      # Note: you may call this method only after optimize! was called.
      # 
      def deoptimize!(lang)
        optimized_methods(lang).each do |meth|
          alias_method(:"#{meth}", :"#{meth}_PureRuby")
        end
      end
      
      # Executes code in a block with optimizations turned on.
      # This ensures that appropriate <tt>deoptimize!</tt> method is called.
      #
      def optimized_with(lang)
        optimize!(lang)
        yield
      ensure
        deoptimize!(lang)
      end
    end
  end
end
