#!/usr/bin/env ruby
require "test/unit"
SRC_DIR = File.expand_path(File.dirname(__FILE__)) + "/" unless
  defined?(SRC_DIR)
%w(ext lib cli).each do |dir|
  $: <<  SRC_DIR + "../#{dir}"
end

require File.join(SRC_DIR, "helper.rb")
include TestHelper

# Test of C extension ruby_debug.so
class TestSetShow < Test::Unit::TestCase
  require 'stringio'

  # Test initial variables and setting/getting state.
  def test_basic
    Dir.chdir(SRC_DIR) do 
      assert_equal(true, 
                   run_debugger("setshow", 
                                "--script setshow.cmd -- gcd.rb 3 5"))
    end
  end
end
