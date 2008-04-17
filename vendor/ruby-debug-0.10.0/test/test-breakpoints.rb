#!/usr/bin/env ruby
require "test/unit"
require "fileutils"

# require "rubygems"
# require "ruby-debug"
# Debugger.start

SRC_DIR = File.expand_path(File.dirname(__FILE__)) + "/" unless 
  defined?(SRC_DIR)

require File.join(SRC_DIR, "helper.rb")

include TestHelper

# Test frame commands
class TestBreakpoints < Test::Unit::TestCase
  require 'stringio'

  # Test commands in stepping.rb
  def test_basic
    Dir.chdir(SRC_DIR) do 
      assert_equal(true, 
                   run_debugger("breakpoints", 
                                "--script breakpoints.cmd -- gcd.rb 3 5"))
    end
  end
end
