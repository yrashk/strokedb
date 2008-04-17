module Debugger

  module ColumnizeFunctions
    # Display a list of strings as a compact set of columns.
    #
    #  Each column is only as wide as necessary.
    #  Columns are separated by two spaces (one was not legible enough).
    #  Adapted from the routine of the same name in cmd.py
    def columnize(list, displaywidth=80)
      if not list.is_a?(Array)
        return "Expecting an Array, got #{list.class}\n"
      end
      if list.size == 0
        return  "<empty>\n"
      end
      nonstrings = []
      for str in list do
        nonstrings << str unless str.is_a?(String)
      end
      if nonstrings.size > 0
        return "Nonstrings: %s\n" % nonstrings.map {|non| non.to_s}.join(', ')
      end
      if 1 == list.size
        return "#{list[0]}\n"
      end
      # Try every row count from 1 upwards
      nrows = ncols = 0
      colwidths = []
      1.upto(list.size) do 
        colwidths = []
        nrows += 1
        ncols = (list.size + nrows-1) / nrows
        totwidth = -2
        # Debugger.debugger if nrows > 1
        0.upto(ncols-1) do |col|
          colwidth = 0
          0.upto(nrows-1) do |row|
            i = row + nrows*col
            if i >= list.size
              break
            end
            colwidth = [colwidth, list[i].size].max
          end
          colwidths << colwidth
          totwidth += colwidth + 2
          if totwidth > displaywidth
            break
          end
        end
        if totwidth <= displaywidth
          break
        end
      end
      s = ''
      0.upto(nrows-1) do |row| 
        texts = []
        0.upto(ncols-1) do |col|
          i = row + nrows*col
          if i >= list.size
            x = ""
          else
            x = list[i]
          end
          texts << x
        end
        while texts and texts[-1] == ''
          texts = texts[0..-2]
        end
        0.upto(texts.size-1) do |col|
          texts[col] = texts[col].ljust(colwidths[col])
        end
        s += "%s\n" % texts.join("  ")
      end
      return s
    end
  end

  module ParseFunctions
    # Parse 'str' of command 'cmd' as an integer between
    # min and max. If either min or max is nil, that
    # value has no bound.
    def get_int(str, cmd, min=nil, max=nil, default=1)
      return default unless str
      begin
        int = Integer(str)
        if min and int < min
          print "%s argument '%s' needs to at least %s.\n" % [cmd, str, min]
          return nil
        elsif max and int > max
          print "%s argument '%s' needs to at most %s.\n" % [cmd, str, max]
          return nil
        end
        return int
      rescue
        print "%s argument '%s' needs to be a number.\n" % [cmd, str]
        return nil
      end
    end

    # Return true if arg is 'on' or 1 and false arg is 'off' or 0.
    # Any other value raises RuntimeError.
    def get_onoff(arg, default=nil, print_error=true)
      if arg.nil? or arg == ''
        if default.nil?
          if print_error
            print "Expecting 'on', 1, 'off', or 0. Got nothing.\n"
            raise RuntimeError
          end
          return default
        end
      end
      case arg.downcase
      when '1', 'on'
        return true
      when '0', 'off'
        return false
      else
        if print_error
          print "Expecting 'on', 1, 'off', or 0. Got: %s.\n" % arg.to_s
          raise RuntimeError
        end
      end
    end

    # Return 'on' or 'off' for supplied parameter. The parmeter should
    # be true, false or nil.
    def show_onoff(bool)
      if not [TrueClass, FalseClass, NilClass].member?(bool.class)
        return "??"
      end
      return bool ? 'on' : 'off'
    end
  end
end
