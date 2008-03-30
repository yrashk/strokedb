module Debugger
  # Mix-in module to assist in command parsing.
  module EnableDisableFunctions # :nodoc:
    def enable_disable_breakpoints(is_enable, args)
      breakpoints = Debugger.breakpoints.sort_by{|b| b.id }
      largest = breakpoints.inject(0){|largest, b| largest = b.id if b.id > largest}
      if 0 == largest
        print "No breakpoints have been set.\n"
        return
      end
      args.each do |pos|
        pos = get_int(pos, "#{is_enable} breakpoints", 1, largest)
        return nil unless pos
        breakpoints.each do |b|
          if b.id == pos 
            b.enabled = ("Enable" == is_enable)
            return
          end
        end
      end
    end

    def enable_disable_display(is_enable, args)
      args.each do |pos|
        pos = get_int(pos, "#{is_enable} display", 1, @state.display.size)
        return nil unless pos
        @state.display[pos-1][0] = ("Enable" == is_enable)
      end
    end

  end

  class EnableCommand < Command # :nodoc:
    SubcmdStruct=Struct.new(:name, :min, :short_help) unless
      defined?(SubcmdStruct)
    Subcommands = 
      [
       ['breakpoints', 2, "Enable specified breakpoints"],
       ['display', 2, "Enable some expressions to be displayed when program stops"],
      ].map do |name, min, short_help| 
      SubcmdStruct.new(name, min, short_help)
    end unless defined?(Subcommands)

    def regexp
      /^\s* en(?:able)? (?:\s+(.*))?$/ix
    end
    
    def execute
      if not @match[1]
        print "\"enable\" must be followed \"display\", \"breakpoints\"" +
          " or breakpoint numbers.\n"
      else
        args = @match[1].split(/[ \t]+/)
        subcmd = args.shift.downcase
        for try_subcmd in Subcommands do
          if (subcmd.size >= try_subcmd.min) and
              (try_subcmd.name[0..subcmd.size-1] == subcmd)
            send("enable_#{try_subcmd.name}", args)
            return
          end
        end
        send("enable_breakpoints", args.unshift(subcmd))
      end
    end
    
    def enable_breakpoints(args)
      enable_disable_breakpoints("Enable", args)
    end
    
    def enable_display(args)
      enable_disable_display("Enable", args)
    end
    
    class << self
      def help_command
        'enable'
      end

      def help(cmd)
        s = %{
          Enable some things.
          This is used to cancel the effect of the "disable" command.
          -- 
          List of enable subcommands:
          --  
        }
        for subcmd in Subcommands do
          s += "enable #{subcmd.name} -- #{subcmd.short_help}\n"
        end
        return s
      end
    end
  end

  class DisableCommand < Command # :nodoc:
    SubcmdStruct=Struct.new(:name, :min, :short_help) unless
      defined?(SubcmdStruct)
    Subcommands = 
      [
       ['breakpoints', 2, "Disable specified breakpoints"],
       ['display', 2, "Disable some display expressions when program stops"],
      ].map do |name, min, short_help| 
      SubcmdStruct.new(name, min, short_help)
    end unless defined?(Subcommands)

    def regexp
      /^\s* dis(?:able)? (?:\s+(.*))?$/ix
    end
    
    def execute
      if not @match[1]
        print "\"disable\" must be followed \"display\", \"breakpoints\"" +
          " or breakpoint numbers.\n"
      else
        args = @match[1].split(/[ \t]+/)
        subcmd = args.shift.downcase
        for try_subcmd in Subcommands do
          if (subcmd.size >= try_subcmd.min) and
              (try_subcmd.name[0..subcmd.size-1] == subcmd)
            send("disable_#{try_subcmd.name}", args)
            return
          end
        end
        send("disable_breakpoints", args.unshift(subcmd))
      end
    end
    
    def disable_breakpoints(args)
      enable_disable_breakpoints("Disable", args)
    end
    
    def disable_display(args)
      enable_disable_display("Disable", args)
    end
    
    class << self
      def help_command
        'disable'
      end

      def help(cmd)
        s = %{
          Disable some things.

          A disabled item is not forgotten, but has no effect until reenabled.
          Use the "enable" command to have it take effect again.
          -- 
          List of disable subcommands:
          --  
        }
        for subcmd in Subcommands do
          s += "disable #{subcmd.name} -- #{subcmd.short_help}\n"
        end
        return s
      end
    end
  end

end # module Debugger
