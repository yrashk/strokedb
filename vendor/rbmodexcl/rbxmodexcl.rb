
class Object

  def unextend(mod)
    raise ArgumentError, "Module is expected" unless mod.is_a?(Module)
    raise ArgumentError, "unextending Kernel is prohibited" if mod == Kernel
    prev = p = metaclass
    while p 
      if (p == mod || (p.respond_to?(:module) && p.module == mod)) 
        prev.set_superclass(p.direct_superclass)
        # remove cache
        self.methods.each do |name|
          name = self.metaclass.send(:normalize_name,name)
          Rubinius::VM.reset_method_cache(name)
        end
        #
        mod.send(:unextended, self) if mod.respond_to?(:unextended)
        return self
      end
      prev = p
      p = p.direct_superclass
    end

  end

  def uninclude(mod)
    raise ArgumentError, "Module is expected" unless mod.is_a?(Module)
    raise ArgumentError, "unincluding Kernel is prohibited" if mod == Kernel
    prev = p = self
    while p 
      if (p == mod || (p.respond_to?(:module) && p.module == mod)) 
        prev.superclass=(p.direct_superclass)
        # remove cache
        self.methods.each do |name|
          name = self.metaclass.send(:normalize_name,name)
          Rubinius::VM.reset_method_cache(name)
        end
        #
        mod.send(:unincluded, self) if mod.respond_to?(:unincluded)
        return self
      end
      prev = p
      p = p.direct_superclass
    end

  end

end