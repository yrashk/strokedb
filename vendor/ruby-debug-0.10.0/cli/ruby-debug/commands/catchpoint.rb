module Debugger
  class CatchCommand < Command # :nodoc:
    self.control = true

    def regexp
      /^\s*cat(?:ch)?(?:\s+(.+))?$/
    end

    def execute
      if excn = @match[1]
        if excn == 'off'
          Debugger.catchpoint = nil
          print "Clear catchpoint.\n"
        else
          Debugger.catchpoint = excn
          print "Set catchpoint %s.\n", excn
        end
      else
        if Debugger.catchpoint
          print "Catchpoint %s.\n", Debugger.catchpoint
        else
          print "No catchpoint.\n"
        end
      end
    end

    class << self
      def help_command
        'catch'
      end

      def help(cmd)
        %{
          cat[ch]\t\t\tshow catchpoint
          cat[ch] <an Exception>\tset catchpoint to an exception
        }
      end
    end
  end
end