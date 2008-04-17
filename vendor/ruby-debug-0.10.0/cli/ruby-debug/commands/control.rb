module Debugger
  class QuitCommand < Command # :nodoc:
    self.control = true

    def regexp
      /^\s*(?:q(?:uit)?|exit)\s*(\s+unconditionally)?\s*$/
    end

    def execute
      if @match[1] or confirm("Really quit? (y/n) ") 
        Debugger.save_history if Debugger.respond_to? :save_history
        exit! # exit -> exit!: No graceful way to stop threads...
      end
    end

    class << self
      def help_command
        %w[quit exit]
      end

      def help(cmd)
        %{
          q[uit] [unconditionally]\texit from debugger. 
          exit\talias to quit

          Normally we prompt before exiting. However if the parameter
          "unconditionally" is given, we stop without asking further questions.
        }
      end
    end
  end
  
  class RestartCommand < Command # :nodoc:
    self.control = true

    def regexp
      / ^\s*
      (?:restart|R)
      (?:\s+ (\S?.*\S))? \s*
      $
      /ix
    end
    
    def execute
      if not defined? Debugger::RDEBUG_SCRIPT
        # FIXME? Should ask for confirmation? 
        print "Debugger was not called from the outset...\n"
        rdebug_script = ''
      else 
        rdebug_script = Debugger::RDEBUG_SCRIPT + " "
      end
      prog_script = Debugger::PROG_SCRIPT
      begin
        Dir.chdir(Debugger::INITIAL_DIR)
      rescue
        print "Failed to change initial directory #{Debugger::INITIAL_DIR}"
      end
      if not File.exists?(prog_script)
        print "Ruby program #{prog_script} doesn't exist\n"
        return
      end
      if not File.executable?(prog_script) and rdebug_script == ''
        print "Ruby program #{prog_script} doesn't seem to be executable...\n"
        print "We'll add a call to Ruby.\n"
        ruby = begin defined?(Gem) ? Gem.ruby : "ruby" rescue "ruby" end
        rdebug_script = "#{ruby} -I#{$:.join(' -I')} #{prog_script}"
      end
      if @match[1]
        argv = [prog_script] + @match[1].split(/[ \t]+/)
      else
        if not defined? Command.settings[:argv]
          print "Arguments have not been set. Use 'set args' to set them.\n"
          return
        else
          argv = Command.settings[:argv]
        end
      end
      args = argv.join(" ")

      # An execv would be preferable to the "exec" below.
      cmd = rdebug_script + args
      print "Re exec'ing:\n\t#{cmd}\n"
      exec cmd
    rescue Errno::EOPNOTSUPP
      print "Restart command is not available at this time.\n"
    end

    class << self
      def help_command
        'restart'
      end

      def help(cmd)
        %{
          restart|R [args] 
          Restart the program. This is is a re-exec - all debugger state
          is lost. If command arguments are passed those are used.
        }
      end
    end
  end

  class InterruptCommand < Command # :nodoc:
    self.event = false
    self.control = true
    self.need_context = true
    
    def regexp
      /^\s*i(?:nterrupt)?\s*$/
    end
    
    def execute
      unless Debugger.interrupt_last
        context = Debugger.thread_context(Thread.main)
        context.interrupt
      end
    end
    
    class << self
      def help_command
        'interrupt'
      end
      
      def help(cmd)
        %{
          i[nterrupt]\tinterrupt the program
        }
      end
    end
  end
end
