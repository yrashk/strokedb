# Very alpha patch to RubyInline supporting inlining Java code.
# Copyright 2008 Charles Nutter.
# See http://headius.blogspot.com/2008/03/rubyinline-for-jruby-easy.html

require 'rubygems'
require 'inline'
require 'java'

# Add the inline cache dir to CLASSPATH
$CLASSPATH << Inline.directory

module Inline
  
  # A Java builder for RubyInline. Provides the basic methods needed to
  # allow assembling a set of Java methods that compile into a class and
  # get bound to the same names in the containing module.
  class Java
    JFile = java.io.File
    import javax.tools.ToolProvider
    import javax.tools.SimpleJavaFileObject
    import javax.tools.StandardLocation

    def initialize(mod)
      @context = mod
      @src = ""
      @imports = []
      @sigs = []
    end
    
    def load_cache
      false
    end
    
    # Set the package to use for the Java class being generated, as in
    # builder.package "org.foo.bar"
    def package(pkg)
      @pkg = pkg
    end

    # Add an "import" line with the given class, as in
    # builder.import "java.util.ArrayList". The imports will be composed
    # into an appropriate block of code and added to the top of the source.
    def import(cls)
      @imports << cls
    end

    # Add a Java method to the built Java source. This expects the method to
    # be public and static, so it can be called as a function.
    def java(src)
      @src << src << "\n"
      signature = src.match(/public static\W+(\w+)\W+([a-zA-Z0-9_]+)\((.*)\)/)
      raise "Could not parse method signature" unless signature
      @sigs << [signature[1], signature[2], signature[3]]
    end

    def build
      compiler = ToolProvider.system_java_compiler
      file_mgr = compiler.get_standard_file_manager(nil, nil, nil)
      file_mgr.set_location(StandardLocation::CLASS_OUTPUT, [JFile.new(Inline.directory)])
      
      if @pkg
        directory = "#{Inline.directory}/#{@pkg.gsub('.', '/')}"
        unless File.directory? directory then
          $stderr.puts "NOTE: creating #{directory} for RubyInline" if $DEBUG
          FileUtils.mkdir_p directory
        end
        
        @name = "Java#{@src.hash.abs}"
        @load_name = "#{@pkg}.#{@name}"
        filename = "#{directory}/#{@name}.java"
      
        imports = "import " + @imports.join(";\nimport ") + ";" if @imports.size > 0
        full_src = "
          package #{@pkg};
          #{imports}
          public class #{@name} {
          #{@src}
          }
        "
      else
        @load_name = @name = "Java#{@src.hash.abs}"
        filename = "#{Inline.directory}/#{@name}.java"
      
        imports = "import " + @imports.join(";\nimport ") + ";" if @imports.size > 0
        full_src = "
          #{imports}
          public class #{@name} {
          #{@src}
          }
        "
      end
      
      File.open(filename, "w") {|file| file.write(full_src)}
      file_objs = file_mgr.get_java_file_objects_from_strings([filename])
      
      compiler.get_task(nil, file_mgr, nil, nil, nil, file_objs).call
      file_mgr.close
    end

    def load
      @sigs.each do |sig|
        @context.module_eval "const_set :#{@name}, ::Java::#{@load_name}; p '#{@load_name}'; def #{sig[1]}(*args); #{@name}.#{sig[1]}(*args); end"
      end
    end
  end
end
