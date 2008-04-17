module Debugger
  class AddBreakpoint < Command # :nodoc:
    self.control = true
    
    def regexp
      / ^\s*
        b(?:reak)?
        (?: \s+
        (?:
          (\d+) |
          (.+?)[:.#]([^.:\s]+)
        ))?
        (?:\s+
          if\s+(.+)
        )?
        $
      /x
    end

    def execute
      if @match[1]
        line, _, _, expr = @match.captures
      else
        _, file, line, expr = @match.captures
      end

      full_file = nil
      if file.nil?
        full_file = @state.file
        file = File.basename(@state.file)
        if line.nil? 
          # Set breakpoint at current line
          line = @state.line.to_s
        end
      elsif line !~ /^\d+$/
        # See if "line" is a method/function name
        klass = debug_silent_eval(file)
        if klass && klass.kind_of?(Module)
          class_name = klass.name if klass
        else
          print "Unknown class #{file}.\n"
          throw :debug_error
        end
      else
        file = File.expand_path(file) if file.index(File::SEPARATOR) || \
        File::ALT_SEPARATOR && file.index(File::ALT_SEPARATOR)
        full_file = file
      end
      
      if line =~ /^\d+$/
        line = line.to_i
        lines = Debugger.source_for(full_file)
        if not lines 
          print "No source file named %s\n", file
        elsif lines.size < line
          print "No line %d in file \"%s\"\n", line, file
        else
          b = Debugger.add_breakpoint file, line, expr
          print "Breakpoint %d file %s, line %s\n", b.id, file, line.to_s
        end
      else
        method = line.intern.id2name
        b = Debugger.add_breakpoint class_name, method, expr
        print "Breakpoint %d at %s::%s\n", b.id, class_name, method.to_s
      end
    end

    class << self
      def help_command
        'break'
      end

      def help(cmd)
        %{
          b[reak] file:line [if expr]
          b[reak] class(.|#)method [if expr]
          \tset breakpoint to some position, (optionally) if expr == true
        }
      end
    end
  end

  class DeleteBreakpointCommand < Command # :nodoc:
    self.control = true

    def regexp
      /^\s*del(?:ete)?(?:\s+(.*))?$/
    end

    def execute
      brkpts = @match[1]
      unless brkpts
        if confirm("Delete all breakpoints? (y or n) ")
          Debugger.breakpoints.clear
        end
      else
        brkpts.split(/[ \t]+/).each do |pos|
          pos = get_int(pos, "Delete", 1)
          return unless pos
          unless Debugger.remove_breakpoint(pos)
            print "No breakpoint number %d\n", pos
          end
        end
      end
    end

    class << self
      def help_command
        'delete'
      end

      def help(cmd)
        %{
          del[ete][ nnn...]\tdelete some or all breakpoints
        }
      end
    end
  end
end
