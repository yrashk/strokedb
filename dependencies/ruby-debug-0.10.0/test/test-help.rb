#!/usr/bin/env ruby

# require "rubygems"
# require "ruby-debug" ; Debugger.start

require "test/unit"
SRC_DIR = File.expand_path(File.dirname(__FILE__)) + "/" unless 
  defined?(SRC_DIR)
%w(ext lib cli).each do |dir|
  $: <<  File.join(SRC_DIR, "..", dir)
end
require "ruby_debug"
require SRC_DIR + "/../cli/ruby-debug.rb"

def cheap_diff(got_lines, correct_lines)
  correct_lines.each_with_index do |line, i|
    correct_lines[i].chomp!
    if got_lines[i] != correct_lines[i]
      puts "difference found at line #{i+1}"
      puts "got : #{got_lines[i]}"
      puts "need: #{correct_lines[i]}"
      return false
    end
    return correct_lines.size == got_lines.size
  end
end

# Test of C extension ruby_debug.so
class TestCmd < Test::Unit::TestCase
  require 'stringio'

  # Test initial variables and setting/getting state.
  def test_basic
    testbase = 'help'
    op = StringIO.new("", "w")
    script = File.join(SRC_DIR, "#{testbase}.cmd")
    Debugger.const_set('Version', "unit testing")
    Debugger.run_script(script, op)
    got_lines = op.string.split("\n")
    right_file = File.join(SRC_DIR, "#{testbase}.right")
    correct_lines = File.readlines(right_file)
    assert cheap_diff(got_lines, correct_lines)
  end
end
