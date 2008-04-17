module StrokeDB
  class ::Class
    # Declare which methods are optimized for particular language. 
    # It is assumed, that optimized method name looks that way: 
    # <tt>method_name_(language name)</tt>
    #
    # If you supply a block of code, it will be executed in a context of a class
    # each time <tt>optimize!</tt> is called.
    #
    # You may add some exception handling where you call <tt>optimize!</tt>.
    #
    # Example: 
    #
    #    # assume, there're methods find_C and insert_C
    #    declare_optimized_methods(:C, :find, :insert) { require 'bundle' }</tt>
    #
    def declare_optimized_methods(lang, *meths, &block)
      meths.flatten!
      @optimized_methods ||= {}
      @optimized_methods_init ||= {}
      @optimized_methods[lang.to_s] = meths
      @optimized_methods_init[lang.to_s] = block
      extend ClassOptimization::ClassMethods
    end
    
    # Returns a list of optimized methods for a given language.
    # If no language given, a Hash is returned where key is a language name.
    #
    def optimized_methods(lang = nil)
      @optimized_methods ||= {}
      return @optimized_methods unless lang 
      @optimized_methods[lang.to_s] || []
    end
  end
  module ClassOptimization
    module ClassMethods
      # Switches methods into optimized versions as declared in
      # <tt>declare_optimized_methods</tt>.
      # Pure ruby methods become accessible with suffix _PureRuby.
      #
      def optimize!(lang)
        if block = @optimized_methods_init[lang.to_s]
          self.instance_eval(&block)
        end
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
      
      # Iterates through all the optimizations. Non-optimized
      # mode ("pure Ruby") is yielded first. 
      # Useful for testing and benchmarks.
      #
      # Example:
      #
      #    Klass.with_optimizations(:InlineC) do |lang|
      #      puts "Klass#some_method is written in #{lang}"
      #      puts Klass.new.some_method
      #    end
      #
      def with_optimizations(*langs)
        langs.flatten!
        yield("pure Ruby")
        langs.each do |lang|
          optimized_with(lang) do
            yield(lang)
          end
        end
        self
      end
    end
  end
end
