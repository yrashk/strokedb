module Debugger
  class ListCommand < Command # :nodoc:

    register_setting_get(:autolist) do
      ListCommand.always_run 
    end
    register_setting_set(:autolist) do |value|
      ListCommand.always_run = value
    end

    def regexp
      /^\s*l(?:ist)?(?:\s*([-=])|\s+(.+))?$/
    end

    def execute
      listsize = Command.settings[:listsize]
      if !@match || !(@match[1] || @match[2])
        b = @state.previous_line ? 
        @state.previous_line + listsize : @state.line - (listsize/2)
        e = b + listsize - 1
      elsif @match[1] == '-'
        b = @state.previous_line ? 
        @state.previous_line - listsize : @state.line - (listsize/2)
        e = b + listsize - 1
      elsif @match[1] == '='
        @state.previous_line = nil
        b = @state.line - (listsize/2)
        e = b + listsize -1
      else
        b, e = @match[2].split(/[-,]/)
        if e
          b = b.to_i
          e = e.to_i
        else
          b = b.to_i - (listsize/2)
          e = b + listsize - 1
        end
      end
      @state.previous_line = b
      display_list(b, e, @state.file, @state.line)
    end

    class << self
      def help_command
        'list'
      end

      def help(cmd)
        %{
          l[ist]\t\tlist forward
          l[ist] -\tlist backward
          l[ist] =\tlist current line
          l[ist] nn-mm\tlist given lines
          * NOTE - to turn on autolist, use 'set autolist'
        }
      end
    end

    private

    def display_list(b, e, file, line)
      print "[%d, %d] in %s\n", b, e, file
      if lines = Debugger.source_for(file)
        n = 0
        b.upto(e) do |n|
          if n > 0 && lines[n-1]
            if n == line
              print "=> %d  %s\n", n, lines[n-1].chomp
            else
              print "   %d  %s\n", n, lines[n-1].chomp
            end
          end
        end
      else
        print "No sourcefile available for %s\n", file
      end
    end
  end

  class ReloadCommand < Command # :nodoc:
    self.control = true

    register_setting_get(:reload_source_on_change) do 
      Debugger.reload_source_on_change
    end
    register_setting_set(:reload_source_on_change) do |value|
      Debugger.reload_source_on_change = value
    end
    
    def regexp
      /^\s*r(?:eload)?$/
    end
    
    def execute
      Debugger.source_reload
      print "Source code is reloaded. Automatic reloading is #{source_reloading}.\n"
    end
    
    private
    
    def source_reloading
      Debugger.reload_source_on_change ? 'on' : 'off'
    end
    
    class << self
      def help_command
        'reload'
      end

      def help(cmd)
        %{
          r[eload]\tforces source code reloading
        }
      end
    end
  end
end
