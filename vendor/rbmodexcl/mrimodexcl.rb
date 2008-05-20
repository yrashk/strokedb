require 'rubygems'
require 'inline'

class Object
  inline(:C) do |builder|
    builder.prefix %{
      static VALUE
      rb_obj_dummy()
      {
        return Qnil;
      }
    }
    builder.add_to_init %{
      rb_define_private_method(rb_cModule, "unextended", rb_obj_dummy, 1);
    }
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
              rb_funcall(mod, rb_intern("unextended"), 1, self);
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

class Class

    inline(:C) do |builder|
      builder.prefix %{
        static VALUE
        rb_obj_dummy()
        {
          return Qnil;
        }
      }
      builder.add_to_init %{
        rb_define_private_method(rb_cModule, "unincluded", rb_obj_dummy, 1);
      }
      builder.c %{  
        VALUE uninclude(VALUE mod) 
        {
          VALUE p, prev;
          Check_Type(mod, T_MODULE);
          if (mod == rb_mKernel) 
            rb_raise(rb_eArgError, "unincluding Kernel is prohibited");

            p = self;

            while (p) {
              if (p == mod || RCLASS(p)->m_tbl == RCLASS(mod)->m_tbl) {
                RCLASS(prev)->super = RCLASS(p)->super;
                rb_clear_cache();
                rb_funcall(mod, rb_intern("unincluded"), 1, self);
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