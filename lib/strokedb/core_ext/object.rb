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
      VALUE exclude(VALUE mod) 
      {
        VALUE p, prev;
        Check_Type(mod, T_MODULE);

        p = (TYPE(self) == T_CLASS) ? self : rb_singleton_class(self);

        while (p) {
          if (p == mod || RCLASS(p)->m_tbl == RCLASS(mod)->m_tbl) {
            RCLASS(prev)->super = RCLASS(p)->super;
            rb_clear_cache();
            return Qtrue;
          }
          prev = p;
          p = RCLASS(p)->super;
        }
        return Qfalse;
      }
    }
  end


end