module Debugger
  class InfoCommand < Command # :nodoc:
    SubcmdStruct=Struct.new(:name, :min, :short_help) unless
      defined?(SubcmdStruct)
    Subcommands = 
      [
       ['args', 1, "Argument variables of current stack frame"],
       ['breakpoints', 1, "Status of user-settable breakpoints"],
       ['display', 2, "Expressions to display when program stops"],
       ['file', 1, "File names and timestamps of files read in"],
       ['global_variables', 2, "global variables"],
       ['instance_variables', 2, "instance variables"],
       ['line', 2, "Line number and file name of current position in source"],
       ['locals', 2, "Local variables of the current stack frame"],
       ['program', 2, "Execution status of the program"],
       ['stack', 2, "Backtrace of the stack"],
       ['threads', 1, "IDs of currently known threads"],
       ['variables', 1, "local and instance variables"]
      ].map do |name, min, short_help| 
      SubcmdStruct.new(name, min, short_help)
    end unless defined?(Subcommands)

    def regexp
      /^\s* i(?:nfo)? (?:\s+(.*))?$/ix
    end
    
    def execute
      if not @match[1]
        print "\"info\" must be followed by the name of an info command:\n"
        print "List of info subcommands:\n\n"
        for subcmd in Subcommands do
          print "info #{subcmd.name} -- #{subcmd.short_help}\n"
        end
      else
        subcmd, args = @match[1].split(/[ \t]+/)
        subcmd.downcase!
        for try_subcmd in Subcommands do
          if (subcmd.size >= try_subcmd.min) and
              (try_subcmd.name[0..subcmd.size-1] == subcmd)
            send("info_#{try_subcmd.name}", args)
            return
          end
        end
        print "Unknown info command #{subcmd}\n"
      end
    end
    
    def info_args(*args)
      locals = @state.context.frame_locals(@state.frame_pos)
      args = @state.context.frame_args(@state.frame_pos)
      args.each do |name|
        s = "#{name} = #{locals[name].inspect}"
        if s.size > self.class.settings[:width]
          s[self.class.settings[:width]-3 .. -1] = "..."
        end
        print "#{s}\n"
      end
    end
    
    def info_breakpoints(*args)
      unless Debugger.breakpoints.empty?
        print "Num Enb What\n"
        Debugger.breakpoints.sort_by{|b| b.id }.each do |b|
          if b.expr.nil?
            print "%3d %s   at %s:%s\n", 
            b.id, (b.enabled? ? 'y' : 'n'), b.source, b.pos
          else
            print "%3d %s   at %s:%s if %s\n", 
            b.id, (b.enabled? ? 'y' : 'n'), b.source, b.pos, b.expr
          end
        end
      else
        print "No breakpoints.\n"
      end
    end
    
    def info_display(*args)
      if @state.display.size > 0
        print "Auto-display expressions now in effect:\n"
        print "Num Enb Expression\n"
        n = 1
        for d in @state.display
          print "%3d: %s  %s\n", n, (d[0] ? 'y' : 'n'), d[1] if
            d[0] != nil
          n += 1
        end
      else
        print "There are no auto-display expressions now.\n"
      end
    end
    
    def info_file(*args)
      SCRIPT_LINES__.each do |file, value|
        print "File %s %s\n", file, SCRIPT_TIMESTAMPS__[file]
      end
    end
    
    def info_instance_variables(*args)
      obj = debug_eval('self')
      var_list(obj.instance_variables)
    end
    
    def info_line(*args)
      print "Line %d of \"%s\"\n",  @state.line, @state.file
    end
    
    def info_locals(*args)
      locals = @state.context.frame_locals(@state.frame_pos)
      locals.keys.sort.each do |name|
        ### FIXME: make a common routine
        begin
          s = "#{name} = #{locals[name].inspect}"
        rescue
          begin
          s = "#{name} = #{locals[name].to_s}"
          rescue
            s = "*Error in evaluation*"
          end
        end  
        if s.size > self.class.settings[:width]
          s[self.class.settings[:width]-3 .. -1] = "..."
        end
        print "#{s}\n"
      end
    end
    
    def info_program(*args)
      if @state.context.dead? 
        print "The program being debugged is not being run.\n"
        return
      end
      print "Program stopped. "
      case @state.context.stop_reason
      when :step
        print "It stopped after stepping, next'ing or initial start.\n"
      when :breakpoint
        print("It stopped at a breakpoint.\n")
      when :catchpoint
        print("It stopped at a catchpoint.\n")
      when :catchpoint
        print("It stopped at a catchpoint.\n")
      else
        print "unknown reason: %s\n" % @state.context.stop_reason.to_s
      end
    end
    
    def info_stack(*args)
      (0...@state.context.stack_size).each do |idx|
        if idx == @state.frame_pos
          print "--> "
        else
          print "    "
        end
        print_frame(idx)
      end
    end
    
    def info_threads(*args)
      threads = Debugger.contexts.sort_by{|c| c.thnum}.each do |c|
        display_context(c)
      end
    end
    
    def info_global_variables(*args)
      var_list(global_variables)
    end
    
    def info_variables(*args)
      obj = debug_eval('self')
      locals = @state.context.frame_locals(@state.frame_pos)
      locals.keys.sort.each do |name|
        next if name =~ /^__dbg_/ # skip debugger pollution
        ### FIXME: make a common routine
        begin
          s = "#{name} = #{locals[name].inspect}"
        rescue
          begin
            s = "#{name} = #{locals[name].to_s}"
          rescue
            s = "#{name} = *Error in evaluation*"
          end
        end
        if s.size > self.class.settings[:width]
          s[self.class.settings[:width]-3 .. -1] = "..."
        end
        print "#{s}\n"
      end
      var_list(obj.instance_variables, obj.instance_eval{binding()})
    end
    
    class << self
      def help_command
        'info'
      end

      def help(cmd)
        s = %{
          Generic command for showing things about the program being debugged.
          -- 
          List of info subcommands:
          --  
        }
        for subcmd in Subcommands do
          s += "info #{subcmd.name} -- #{subcmd.short_help}\n"
        end
        return s
      end
    end
  end
end
