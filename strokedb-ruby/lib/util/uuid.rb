begin
  module StrokeDB; end
  class FastUUID
    require 'rubygems'
    require 'inline'

    def self.dlpath
      `locate libuuid.so`.split.concat(`locate libuuid.dylib`.split).first
    end

    inline(:C) do |builder|
      builder.add_compile_flags '-I /opt/local/include'
      builder.prefix %{
        #include "dlfcn.h"
        #include "ossp/uuid.h"

        typedef uuid_rc_t (*uuid_create_t)(uuid_t**);
        typedef uuid_rc_t (*uuid_make_t    )(uuid_t *, unsigned int);
        typedef uuid_rc_t (*uuid_export_t  )(const uuid_t *, uuid_fmt_t, void *, size_t *);
        typedef uuid_rc_t (*uuid_destroy_t )(uuid_t *);
        typedef uuid_rc_t (*uuid_import_t  )(uuid_t *, uuid_fmt_t, const void *, size_t);

        static uuid_create_t  uuid_create1;
        static uuid_make_t    uuid_make1;
        static uuid_export_t  uuid_export1;
        static uuid_destroy_t uuid_destroy1;
        static uuid_import_t  uuid_import1;
      }
      builder.add_to_init %{
        VALUE i_dlpath = rb_intern("dlpath");
        VALUE dlpath = rb_funcall(c, i_dlpath, 0);
        void* handle = dlopen(StringValuePtr(dlpath), RTLD_NOW); 

        uuid_create1  = dlsym(handle, "uuid_create");
        uuid_make1    = dlsym(handle, "uuid_make");
        uuid_export1  = dlsym(handle, "uuid_export");
        uuid_destroy1 = dlsym(handle, "uuid_destroy");
        uuid_import1  = dlsym(handle, "uuid_import");

      }
      builder.c %{
        VALUE random_uuid() 
        {
          uuid_t *uuid;
          char *str;
          uuid_create1(&uuid);
          uuid_make1(uuid, UUID_MAKE_V1);
          str = NULL;
          uuid_export1(uuid, UUID_FMT_STR, &str, NULL);
          uuid_destroy1(uuid);
          return rb_str_new2(str);
        }
      }

    end
  end
    
  
  require 'dl/import'
  module LibUUID
    extend DL::Importable
    dlload `locate libuuid.so`.split.concat(`locate libuuid.dylib`.split).first
    typealias("uuid_rc_t", "unsigned int")
    typealias("uuid_fmt_t","unsigned int")
    typealias("size_t","unsigned int")
    typealias("uuid_t *","void *")
    extern "uuid_rc_t uuid_create(uuid_t **)"
    extern "uuid_rc_t uuid_make(uuid_t *, unsigned int)"
    extern "uuid_rc_t uuid_export(const uuid_t *, uuid_fmt_t, void *, size_t *)"
    extern "uuid_rc_t uuid_destroy(uuid_t *)"
    extern "uuid_rc_t uuid_import(uuid_t *, uuid_fmt_t, const void *, size_t)"
  end
  module StrokeDB::Util
    def self.random_uuid
      ptr = DL::PtrData.new(0)
      str = DL::PtrData.new(0)
      str.free = DL::FREE
      LibUUID.uuid_create(ptr.ref)
      LibUUID.uuid_make(ptr,1)
      LibUUID.uuid_export(ptr,1,str.ref,nil)
      LibUUID.uuid_destroy(ptr)
      str.to_s
    end

    def self.random_uuid_raw
      ptr = DL::PtrData.new(0)
      str = DL::PtrData.new(0)
      str.free = DL::FREE
      LibUUID.uuid_create(ptr.ref)
      LibUUID.uuid_make(ptr,1)
      LibUUID.uuid_export(ptr,0,str.ref,nil)
      LibUUID.uuid_destroy(ptr)
      str[0,16].to_s
    end
    
    class ::String
      # Convert to raw (16 bytes) string (self can be already raw or formatted).
      def to_raw_uuid
        if size == 16 
          self.freeze 
        else
            ptr = DL::PtrData.new(0)
            str = DL::PtrData.new(0)
            str.free = DL::FREE
            LibUUID.uuid_create(ptr.ref)
            LibUUID.uuid_import(ptr,1,self,36)
            LibUUID.uuid_export(ptr,0,str.ref,nil)
            LibUUID.uuid_destroy(ptr)
            str[0,16].to_s
        end 
      end
      # Convert to formatted string (self can be raw or already formatted).
      def to_formatted_uuid
        if size == 16 
          ptr = DL::PtrData.new(0)
          str = DL::PtrData.new(0)
          str.free = DL::FREE
          LibUUID.uuid_create(ptr.ref)
          LibUUID.uuid_import(ptr,0,self,16)
          LibUUID.uuid_export(ptr,1,str.ref,nil)
          LibUUID.uuid_destroy(ptr)
          str.to_s
        else
            self.freeze 
        end 
      end
    end
  end
rescue RuntimeError
  puts "Can't load libuuid, using uuidtools"
  require 'uuidtools'
  module StrokeDB::Util

    def self.random_uuid
      ::UUID.random_create.to_s
    end
    def self.random_uuid_raw
      ::UUID.random_create.raw
    end

    class ::String
      # Convert to raw (16 bytes) string (self can be already raw or formatted).
      def to_raw_uuid
        size == 16 ? self.freeze : ::UUID.parse(self).raw
      end
      # Convert to formatted string (self can be raw or already formatted).
      def to_formatted_uuid
        size == 16 ? ::UUID.parse_raw(self).to_s : self.freeze
      end
    end

  end
end