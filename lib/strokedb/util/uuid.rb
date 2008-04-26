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
        #include "uuid.h"

        #define PROLOG(size)               \\
          uuid_t *uuid;                    \\
          char str[size], *strptr = str;   \\
          size_t len = sizeof(str);        \\
          uuid_create(&uuid)

        #define EPILOG(format, size)                 \\
          uuid_export(uuid, format, &strptr, &len),  \\
          uuid_destroy(uuid),                        \\
          rb_str_new(str,size)

        #define CHARS  EPILOG(UUID_FMT_STR, 36)
        #define BINARY EPILOG(UUID_FMT_BIN, 16)
      }
      builder.c %{
        VALUE random_uuid() 
        {
          PROLOG(40);
          uuid_make(uuid, UUID_MAKE_V4);
          return CHARS;
        }
      }
      builder.c %{
        VALUE random_uuid_raw()
        {
          PROLOG(20);
          uuid_make(uuid, UUID_MAKE_V4);
          return BINARY;
        }
      }
      builder.c %{
        VALUE sha1_uuid(VALUE oid)
        {
          uuid_t *uuid_ns;
          PROLOG(40);
          
          uuid_create(&uuid_ns);
          uuid_load(uuid_ns, "ns:OID");
          uuid_make(uuid, UUID_MAKE_V5, uuid_ns, StringValuePtr(oid));

          uuid_destroy(uuid_ns);
          
          return CHARS;
        }
      }
      
      builder.c %{
        VALUE uuid_to_raw(VALUE r_uuid)
        {
          PROLOG(20);
          uuid_import(uuid, UUID_FMT_STR, StringValuePtr(r_uuid), 36);
          return BINARY;
        }
      }

      builder.c %{
        VALUE uuid_to_formatted(VALUE r_uuid)
        {
          PROLOG(40);
          uuid_import(uuid, UUID_FMT_BIN, StringValuePtr(r_uuid), 36);
          return CHARS;
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
    def self.sha1_uuid(oid)
      ::FAST_UUID.sha1_uuid(oid)
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
    def self.sha1_uuid(oid)
      ::UUID.sha1_create(UUID_OID_NAMESPACE, oid).to_s
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

module StrokeDB::Util
  RAW_UUID_SIZE       = random_uuid_raw.size
  FORMATTED_UUID_SIZE = random_uuid.size
end

