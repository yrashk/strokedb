begin
  module StrokeDB; end
  class FastUUID
    require 'rubygems'
    require 'inline'

    C_FLAGS = `uuid-config --cflags`.chomp
    LD_FLAGS = `uuid-config --ldflags --libs`.chomp
    
    inline(:C) do |builder|
      builder.add_compile_flags C_FLAGS
      builder.add_link_flags LD_FLAGS
      builder.prefix %{
        #include "dlfcn.h"
        #include "ossp/uuid.h"
      }
      builder.c %{
        VALUE random_uuid() 
        {
          uuid_t *uuid;
          char *str;
          uuid_create(&uuid);
          uuid_make(uuid, UUID_MAKE_V4);
          str = NULL;
          uuid_export(uuid, UUID_FMT_STR, &str, NULL);
          uuid_destroy(uuid);
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
          uuid_create(&uuid);
          uuid_make(uuid, UUID_MAKE_V4);
          str = NULL;
          uuid_export(uuid, UUID_FMT_BIN, &str, NULL);
          uuid_destroy(uuid);
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
          uuid_create(&uuid);
          uuid_import(uuid, UUID_FMT_STR, STR2CSTR(r_uuid), 36);
          str = NULL;
          uuid_export(uuid, UUID_FMT_BIN, &str, NULL);
          uuid_destroy(uuid);
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
          uuid_create(&uuid);
          uuid_import(uuid, UUID_FMT_BIN, STR2CSTR(r_uuid), 36);
          str = NULL;
          uuid_export(uuid, UUID_FMT_STR, &str, NULL);
          uuid_destroy(uuid);
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