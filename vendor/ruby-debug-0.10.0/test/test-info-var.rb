#!/usr/bin/env ruby
require "test/unit"
require "fileutils"

# require "rubygems"
# require "ruby-debug" ; Debugger.start

SRC_DIR = File.expand_path(File.dirname(__FILE__)) + "/" unless 
  defined?(SRC_DIR)

require File.join(SRC_DIR, "helper.rb")
include TestHelper

# Test info variables command
class TestInfoVar < Test::Unit::TestCase

  def test_info_variables

    Dir.chdir(SRC_DIR) do 

      filter = Proc.new{|got_lines, correct_lines|
        [got_lines[12], correct_lines[12]].each do |s|
          s.sub!(/Mine:0x[0-9,a-f]+/, 'Mine:')
        end
      }

      assert_equal(true, 
                   run_debugger("info-var", 
                                "--script info-var.cmd -- info-var-bug.rb",
                                nil, filter))
    end
  end
end
