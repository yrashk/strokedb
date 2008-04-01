module Debugger
  class SourceCommand < Command # :nodoc:
    self.control = true
    
    def regexp
      /^\s*so(?:urce)?\s+(.+)$/
    end
    
    def execute
      file = File.expand_path(@match[1]).strip
      unless File.exists?(file)
        print "Command file '#{file}' is not found\n"
        return
      end
      Debugger.run_script(file, @state)
    end
    
    class << self
      def help_command
        'source'
      end
      
      def help(cmd)
        %{
          source FILE\texecutes a file containing debugger commands
        }
      end
    end
  end
  
  class SaveCommand < Command # :nodoc:
    self.control = true
    
    def regexp
      /^\s*sa(?:ve)?(?:\s+(.+))?$/
    end
    
    def execute
      unless @match[1]
        print "No filename specified.\n"
        return
      end
      open(@match[1], 'w') do |file|
        Debugger.breakpoints.each do |b|
          file.puts "break #{b.source}:#{b.pos}#{" if #{b.expr}" if b.expr}"
        end
        file.puts "catch #{Debugger.catchpoint}" if Debugger.catchpoint
      end
      print "Saved to '#{@match[1]}'\n"
    end

    class << self
      def help_command
        'save'
      end
      
      def help(cmd)
        %{
          save FILE\tsaves current breakpoints and catchpoint as a script file
        }
      end
    end
  end
end
