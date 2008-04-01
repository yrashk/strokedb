module Debugger  
  class LocalInterface # :nodoc:
    attr_accessor :histfile
    attr_accessor :history_save
    attr_accessor :history_length

    unless defined?(FILE_HISTORY)
      FILE_HISTORY = ".rdebug_hist"
    end
    def initialize()
      @history_save = true
      # take gdb's default
      @history_length = ENV["HISTSIZE"] ? ENV["HISTSIZE"].to_i : 256  
      @histfile = File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", 
                            FILE_HISTORY)
      open(@histfile, 'r') do |file|
        file.each do |line|
          line.chomp!
          Readline::HISTORY << line
        end
      end if File.exists?(@histfile)
    end

    def read_command(prompt)
      readline(prompt, true)
    end
    
    def confirm(prompt)
      readline(prompt, false)
    end
    
    def print(*args)
      STDOUT.printf(*args)
    end
    
    def close
    end
    
    private
    
    begin
      require 'readline'
      class << Debugger
        define_method(:save_history) do
          @histfile ||= File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", 
                                  FILE_HISTORY)
          open(@histfile, 'w') do |file|
            Readline::HISTORY.to_a.last(@history_length).each do |line|
              file.puts line unless line.strip.empty?
            end if @history_save
          end rescue nil
        end
        public :save_history 
      end
      Debugger.debug_at_exit { Debugger.save_history }
      
      def readline(prompt, hist)
        Readline::readline(prompt, hist)
      end
    rescue LoadError
      def readline(prompt, hist)
        @histfile = ''
        @hist_save = false
        STDOUT.print prompt
        STDOUT.flush
        line = STDIN.gets
        exit unless line
        line.chomp!
        line
      end
    end
  end

  class RemoteInterface # :nodoc:
    attr_accessor :histfile
    attr_accessor :history_save
    attr_accessor :history_length

    def initialize(socket)
      @socket = socket
      @history_save = false
      @history_length = 256
      @histfile = ''
    end
    
    def read_command(prompt)
      send_command "PROMPT #{prompt}"
    end
    
    def confirm(prompt)
      send_command "CONFIRM #{prompt}"
    end

    def print(*args)
      @socket.printf(*args)
    end
    
    def close
      @socket.close
    rescue Exception
    end
    
    private
    
    def send_command(msg)
      @socket.puts msg
      result = @socket.gets
      raise IOError unless result
      result.chomp
    end
  end
  
  class ScriptInterface # :nodoc:
    attr_accessor :histfile
    attr_accessor :history_save
    attr_accessor :history_length
    def initialize(file, out, verbose=false)
      @file = file.respond_to?(:gets) ? file : open(file)
      @out = out
      @verbose = verbose
      @history_save = false
      @history_length = 256  # take gdb default
      @histfile = ''
    end
    
    def read_command(prompt)
      while result = @file.gets
        puts "# #{result}" if @verbose
        next if result =~ /^\s*#/
        next if result.strip.empty?
        break
      end
      raise IOError unless result
      result.chomp!
    end
    
    def confirm(prompt)
      'y'
    end
    
    def print(*args)
      @out.printf(*args)
    end
    
    def close
      @file.close
    end
  end
end
