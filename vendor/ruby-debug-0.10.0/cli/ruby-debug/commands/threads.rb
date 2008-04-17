module Debugger
  module ThreadFunctions # :nodoc:
    def display_context(c)
      c_flag = c.thread == Thread.current ? '+' : ' '
      c_flag = '$' if c.suspended?
      d_flag = c.ignored? ? '!' : ' '
      print "%s%s", c_flag, d_flag
      print "%d ", c.thnum
      print "%s\t", c.thread.inspect
      if c.stack_size > 0
        print "%s:%d", c.frame_file(0), c.frame_line(0)
      end
      print "\n"
    end
    
    def parse_thread_num(subcmd, arg)
      if '' == arg
        print "'thread %s' needs a thread number\n" % subcmd
      else
        thread_num = get_int(arg, "thread #{subcmd}", 1)
        return nil unless thread_num
        c = get_context(thread_num)
        case 
        when nil == c
          print "No such thread.\n"
        when @state.context == c
          print "It's the current thread.\n"
        when c.ignored?
          print "Can't #{subcmd} to the debugger thread.\n"
        else # Everything is okay
          return c
        end
      end
      return nil
    end
  end

  class ThreadListCommand < Command # :nodoc:
    self.control = true

    def regexp
      /^\s*th(?:read)?\s+l(?:ist)?\s*$/
    end

    def execute
      threads = Debugger.contexts.sort_by{|c| c.thnum}.each do |c|
        display_context(c)
      end
    end

    class << self
      def help_command
        'thread'
      end

      def help(cmd)
        %{
          th[read] l[ist]\t\t\tlist all threads
        }
      end
    end
  end

  class ThreadStopCommand < Command # :nodoc:
    self.control = true
    self.need_context = true
    
    def regexp
      /^\s*th(?:read)?\s+stop\s*(\S*)\s*$/
    end

    def execute
      c = parse_thread_num("stop", @match[1])
      return unless c 
      c.suspend
      display_context(c)
    end

    class << self
      def help_command
        'thread'
      end

      def help(cmd)
        %{
          th[read] stop <nnn>\t\tstop thread nnn
        }
      end
    end
  end

  class ThreadResumeCommand < Command # :nodoc:
    self.control = true
    self.need_context = true
    
    def regexp
      /^\s*th(?:read)?\s+resume\s*(\S*)\s*$/
    end

    def execute
      c = parse_thread_num("resume", @match[1])
      return unless c 
      if !c.thread.stop?
        print "Already running."
        return
      end
      c.resume
      display_context(c)
    end

    class << self
      def help_command
        'thread'
      end

      def help(cmd)
        %{
          th[read] resume <nnn>\t\tresume thread nnn
        }
      end
    end
  end

  # Thread switch Must come after "Thread resume" because "switch" is
  # optional

  class ThreadSwitchCommand < Command # :nodoc:
    self.control = true
    self.need_context = true
    
    def regexp
      /^\s*th(?:read)?\s*(?:sw(?:itch)?)?\s+(\S+)\s*$/
    end

    def execute
      c = parse_thread_num("switch", @match[1])
      return unless c 
      display_context(c)
      c.stop_next = 1
      c.thread.run
      @state.proceed
    end

    class << self
      def help_command
        'thread'
      end

      def help(cmd)
        %{
          th[read] [sw[itch]] <nnn>\tswitch thread context to nnn
        }
      end
    end
  end

  class ThreadCurrentCommand < Command # :nodoc:
    self.need_context = true
    
    def regexp
      /^\s*th(?:read)?\s*(?:cur(?:rent)?)?\s*$/
    end

    def execute
      display_context(@state.context)
    end

    class << self
      def help_command
        'thread'
      end

      def help(cmd)
        %{
          th[read] [cur[rent]]\t\tshow current thread
        }
      end
    end
  end
end
