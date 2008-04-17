begin
  module StrokeDB; end
  class FastUUID
    require 'rubygems'
    require 'inline'

    def self.dlpath
      dlpath = ['/opt/local/lib/libuuid.dylib',*(`locate libuuid.so`.split.concat(`locate libuuid.dylib`.split))].select{|f| File.exists?(f)}.uniq.first
      raise NotImplementedError, "cannot find libuuid" unless dlpath
      dlpath
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
          uuid_make1(uuid, UUID_MAKE_V4);
          str = NULL;
          uuid_export1(uuid, UUID_FMT_STR, &str, NULL);
          uuid_destroy1(uuid);
          VALUE r = rb_str_new(str,36);
          free(str);
          return r;
        }
      }
      builder.c %{
        VALUE random_uuid_raw()
        {
          uuid_t *uuid;
          char *str;
          uuid_create1(&uuid);
          uuid_make1(uuid, UUID_MAKE_V4);
          str = NULL;
          uuid_export1(uuid, UUID_FMT_BIN, &str, NULL);
          uuid_destroy1(uuid);
          VALUE r = rb_str_new(str,16);
          free(str);
          return r;
        }
      }
      
      builder.c %{
        VALUE uuid_to_raw(VALUE r_uuid)
        {
          uuid_t *uuid;
          char *str;
          uuid_create1(&uuid);
          uuid_import1(uuid, UUID_FMT_STR, STR2CSTR(r_uuid), 36);
          str = NULL;
          uuid_export1(uuid, UUID_FMT_BIN, &str, NULL);
          uuid_destroy1(uuid);
          VALUE r = rb_str_new(str,16);
          free(str);
          return r;
        }
      }

      builder.c %{
        VALUE uuid_to_formatted(VALUE r_uuid)
        {
          uuid_t *uuid;
          char *str;
          uuid_create1(&uuid);
          uuid_import1(uuid, UUID_FMT_BIN, STR2CSTR(r_uuid), 36);
          str = NULL;
          uuid_export1(uuid, UUID_FMT_STR, &str, NULL);
          uuid_destroy1(uuid);
          VALUE r = rb_str_new(str,36);
          free(str);
          return r;
        }
      }

    end
  end
  
  FAST_UUID = FastUUID.new

  class ::String
    # Convert to raw (16 bytes) string (self can be already raw or formatted).
    def to_raw_uuid
      if size == 16 
        self.freeze 
      else
        FAST_UUID.uuid_to_raw(self)
      end 
    end
    # Convert to formatted string (self can be raw or already formatted).
    def to_formatted_uuid
      if size == 16 
        FAST_UUID.uuid_to_formatted(self)
      else
        self.freeze 
      end 
    end
  end
  
  module StrokeDB::Util

    def self.random_uuid
      ::FAST_UUID.random_uuid
    end
    def self.random_uuid_raw
      ::FAST_UUID.random_uuid_raw
    end
    
  end



rescue NotImplementedError, CompilationError
  if $!.is_a?(CompilationError)
    puts "# Can't compile C code, make sure you have ossp-uuid installed"
  else
    puts "# Error: #{$!.message}"
  end
  puts "# Falling back to uuidtools gem"
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