module Debugger
  # Mix-in module to showing settings
  module ShowFunctions # :nodoc:
    def show_setting(setting_name)
      case setting_name
      when /^annotate$/
        Debugger.annotate ||= 0
        return ("Annotation level is #{Debugger.annotate}")
      when /^args$/
        if Command.settings[:argv] and Command.settings[:argv].size > 0
          args = Command.settings[:argv][1..-1].join(' ')
        else
          args = ''
        end
        return "Argument list to give program being debugged when it is started is \"#{args}\"."
      when /^autolist$/
        on_off = Command.settings[:autolist] > 0
        return "autolist is #{show_onoff(on_off)}."
      when /^autoeval$/
        on_off = Command.settings[:autoeval]
        return "autoeval is #{show_onoff(on_off)}."
      when /^autoreload$/
        on_off = Command.settings[:reload_source_on_change]
        return "autoreload is #{show_onoff(on_off)}."
      when /^autoirb$/
        on_off = Command.settings[:autoirb] > 0
        return "autoirb is #{show_onoff(on_off)}."
      when /^basename$/
        on_off = Command.settings[:basename]
        return "basename is #{show_onoff(on_off)}."
      when /^callstyle$/
        style = Command.settings[:callstyle]
        return "Frame call-display style is #{style}."
      when /^debuggertesting$/
        on_off = Command.settings[:debuggertesting]
        return "Currently testing the debugger is #{show_onoff(on_off)}."
      when /^forcestep$/
        on_off = self.class.settings[:force_stepping]
        return "force-stepping is #{show_onoff(on_off)}."
      when /^fullpath$/
        on_off = Command.settings[:full_path]
        return "Displaying frame's full file names is #{show_onoff(on_off)}."
      when /^history(:?\s+(filename|save|size))?$/
        args = @match[1].split
        interface = @state.interface
        if args[1] 
          show_save = show_size = show_filename = false
          prefix = false
          if args[1] == "save"
            show_save = true
          elsif args[1] == "size"
            show_size = true
          elsif args[1] == "filename"
            show_filename = true
          end
        else
          show_save = show_size = show_filename = true
          prefix = true
        end
        s = []
        if show_filename
          msg = (prefix ? "filename: " : "") + 
            "The filename in which to record the command history is " +
                      "#{interface.histfile.inspect}"
          s << msg
        end
        if show_save
          msg = (prefix ? "save: " : "") + 
            "Saving of history save is #{show_onoff(interface.history_save)}."
          s << msg
        end
        if show_size
          msg = (prefix ? "size: " : "") + 
            "Debugger history size is #{interface.history_length}"
          s << msg
        end
        return s.join("\n")
      when /^keep-frame-bindings$/
        on_off = Debugger.keep_frame_binding?
        return "keep-frame-bindings is #{show_onoff(on_off)}."
      when /^linetrace$/
        on_off = Debugger.tracing
        return "line tracing is #{show_onoff(on_off)}."
      when /^linetrace\+$/
        on_off = Command.settings[:tracing_plus]
        if on_off
          return "line tracing style is different consecutive lines."
        else
          return "line tracing style is every line."
        end
      when /^listsize$/
        listlines = Command.settings[:listsize]
        return "Number of source lines to list by default is #{listlines}."
      when /^port$/
        return "server port is #{Debugger::PORT}."
      when /^post-mortem$/
        on_off = Debugger.post_mortem
        return "post-mortem handling is #{show_onoff(on_off)}."
      when /^trace$/
        on_off = Command.settings[:stack_trace_on_error]
        return "Displaying stack trace is #{show_onoff(on_off)}."
      when /^version$/
        return "ruby-debug #{Debugger::VERSION}"
      when /^width$/
        return "width is #{self.class.settings[:width]}."
      else
        return "Unknown show subcommand #{setting_name}."
      end
    end
  end

  class ShowCommand < Command # :nodoc:
    
    SubcmdStruct=Struct.new(:name, :min, :short_help) unless 
      defined?(SubcmdStruct)
    Subcommands = 
      [
       ['annotate', 2, "Show annotation level"],
       ['args', 2, 
        "Show argument list to give program being debugged when it is started"],
       ['autoeval', 4, "Show if unrecognized command are evaluated"],
       ['autolist', 4, "Show if 'list' commands is run on breakpoints"],
       ['autoirb', 4, "Show if IRB is invoked on debugger stops"],
       ['autoreload', 4, "Show if source code is reloaded when changed"],
       ['basename', 1, "Show if basename used in reporting files"],
       ['callstyle', 2, "Show paramater style used showing call frames"],
       ['forcestep', 1, "Show if sure 'next/step' forces move to a new line"],
       ['fullpath', 2, "Show if full file names are displayed in frames"],
       ['history', 2, "Generic command for showing command history parameters"],
       ['keep-frame-bindings', 1, "Save frame binding on each call"],
       ['linetrace', 3, "Show line execution tracing"],
       ['linetrace+', 10, 
        "Show if consecutive lines should be different are shown in tracing"],
       ['listsize', 3, "Show number of source lines to list by default"],
       ['port', 1, "Show server port"],
       ['trace', 1, 
        "Show if a stack trace is displayed when 'eval' raises exception"],
       ['version', 1, 
        "Show what version of the debugger this is"],
       ['width', 1, 
        "Show the number of characters the debugger thinks are in a line"],
      ].map do |name, min, short_help| 
      SubcmdStruct.new(name, min, short_help)
    end unless defined?(Subcommands)
    
    self.control = true

    def regexp
      /^show (?: \s+ (.+) )?$/xi
    end

    def execute
      if not @match[1]
        print "\"show\" must be followed by the name of an show command:\n"
        print "List of show subcommands:\n\n"
        for subcmd in Subcommands do
          print "show #{subcmd.name} -- #{subcmd.short_help}\n"
        end
      else
        subcmd, arg = @match[1].split(/[ \t]+/)
        subcmd.downcase!
        for try_subcmd in Subcommands do
          if (subcmd.size >= try_subcmd.min) and
              (try_subcmd.name[0..subcmd.size-1] == subcmd)
            print "%s\n" % show_setting(try_subcmd.name)
            return
          end
        end
        print "Unknown show command #{subcmd}\n"
      end
    end

    class << self
      def help_command
        "show"
      end

      def help(cmd)
        s = "
          Generic command for showing things about the debugger.

          -- 
          List of show subcommands:
          --  
        "
        for subcmd in Subcommands do
          s += "show #{subcmd.name} -- #{subcmd.short_help}\n"
        end
        return s
      end
    end
  end
end
