module StrokeDB
  class ::Class
    def declare_optimized_methods(lang, *meths)
      meths.flatten!
      @optimized_methods ||= {}
      @optimized_methods[lang.to_s] = meths
      extend ClassOptimization::ClassMethods
    end
    def optimized_methods(lang = nil)
      @optimized_methods ||= {}
      return @optimized_methods unless lang 
      @optimized_methods[lang.to_s]
    end
  end
  module ClassOptimization
    module ClassMethods
      def optimize!(lang)
        optimized_methods(lang).each do |meth|
          alias_method(:"#{meth}_PureRuby", :"#{meth}")
          alias_method(:"#{meth}",          :"#{meth}_#{lang}")
        end
      end
      def deoptimize!(lang)
        optimized_methods(lang).each do |meth|
          alias_method(:"#{meth}", :"#{meth}_PureRuby")
        end
      end
    end
  end
end
