# Some common routines used in testing.

require "fileutils"
# require "diff/lcs"
# require "diff/lcs/hunk"

module TestHelper
  
  def run_debugger(testname, args='', outfile=nil, filter=nil)
    rightfile = File.join(SRC_DIR, "#{testname}.right")
    
    outfile = File.join(SRC_DIR, "#{testname}.out") unless outfile

    if File.exists?(outfile)
      FileUtils.rm(outfile)
    end
    
    ENV['RDEBUG'] = "#{SRC_DIR}tdebug.rb"
    cmd = "/bin/sh #{File.join(SRC_DIR, '../runner.sh')} #{args} >#{outfile}"
    output = `#{cmd}`
    
    got_lines     = File.read(outfile).split(/\n/)
    correct_lines = File.read(rightfile).split(/\n/)
    filter.call(got_lines, correct_lines) if filter
    if cheap_diff(got_lines, correct_lines)
      FileUtils.rm(outfile)
      return true
    end
    return false
  end

  def cheap_diff(got_lines, correct_lines)
    puts got_lines if $DEBUG
    correct_lines.each_with_index do |line, i|
      correct_lines[i].chomp!
      if got_lines[i] != correct_lines[i]
        puts "difference found at line #{i+1}"
        puts "got : #{got_lines[i]}"
        puts "need: #{correct_lines[i]}"
        return false
      end
    end
    if correct_lines.size != got_lines.size
      puts("difference in number of lines: " + 
           "#{correct_lines.size} vs. #{got_lines.size}")
      return false
    end
    return true
  end


  # Adapted from the Ruby Cookbook, Section 6.10: Comparing two files.
  # def diff_as_string(rightfile, checkfile, format=:unified, context_lines=3)
  #   right_data = File.read(rightfile)
  #   check_data = File.read(checkfile)
  #   output = ""
  #   diffs = Diff::LCS.diff(right_data, check_data)
  #   return output if diffs.empty?
  #   oldhunk = hunk = nil
  #   debugger
  #   file_length_difference = 0
  #   diffs.each do |piece|
  #     begin
  #       hunk = Diff::LCS::Hunk.new(right_data, check_data, piece, 
  #                                  context_lines, file_length_difference)
  #       next unless oldhunk
  #
  #       # Hunks may overlap, which is why we need to be careful when our
  #       # diff includes lines of context. Otherwise, we might print
  #       # redundant lines.
  #       if (context_lines > 0) and hunk.overlaps?(oldhunk)
  #         hunk.unshift(oldhunk)
  #         else
  #         output << oldhunk.diff(format)
  #       end
  #     ensure
  #       oldhunk = hunk
  #       output << "\n"
  #     end
  #   end
  
  #   # Handle the last remaining hunk 
  #   output << oldhunk.diff(format) << "\n"
  # end

end

