require 'inline'

# partially extracted from ActiveRecord (http://rubyforge.org/projects/activesupport/)

class Object
  unless respond_to?(:send!)
    # Anticipating Ruby 1.9 neutering send
    alias send! send
  end

  # Tricky, tricky! (-:
  def truthy?
    !!self
  end


  inline(:C) do |builder|
    builder.c %{
      VALUE unextend(VALUE mod) 
      {
        VALUE p, prev;
        Check_Type(mod, T_MODULE);
        if (mod == rb_mKernel) 
          rb_raise(rb_eArgError, "unextending Kernel is prohibited");
      	
        p = rb_singleton_class(self);
        
        while (p) {
            if (p == mod || RCLASS(p)->m_tbl == RCLASS(mod)->m_tbl) {
                RCLASS(prev)->super = RCLASS(p)->super;
                rb_clear_cache();
                return self;
            }
            prev = p;
            p = RCLASS(p)->super;
        }
        return self;
      }
    }
  end


end