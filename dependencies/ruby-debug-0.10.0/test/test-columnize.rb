#!/usr/bin/env ruby
require "test/unit"

$: << File.expand_path(File.dirname(__FILE__)) + '/../ext'
$: << File.expand_path(File.dirname(__FILE__)) + '/../cli'
$: << File.expand_path(File.dirname(__FILE__)) + '/../cli/ruby-debug'
require "ruby_debug"

# Test of Columnize function. Note: Columnize is moving out of ruby-debug,
# so this test will disappear.
class TestColumnize < Test::Unit::TestCase
  include Debugger

  require "command.rb"
  include ColumnizeFunctions
  def test_columize
    assert_equal("one  two  three\n", columnize(["one", "two", "three"]))
    assert_equal("oneitem\n", columnize(["oneitem"]))
    assert_equal(
"one    6hree  11o    16e    21ree  26o    31e    36ree  41o    46e    three\n" +
"two    7ne    12ree  17o    22e    27ree  32o    37e    42ree  47o  \n" +
"three  8wo    13e    18ree  23o    28e    33ree  38o    43e    48ree\n" +
"4ne    9hree  14o    19e    24ree  29o    34e    39ree  44o    one  \n" +
"5wo    10e    15ree  20o    25e    30ree  35o    40e    45ree  two  \n",
                 columnize([
                            "one", "two", "three",
                            "4ne", "5wo", "6hree",
                            "7ne", "8wo", "9hree",
                            "10e", "11o", "12ree",
                            "13e", "14o", "15ree",
                            "16e", "17o", "18ree",
                            "19e", "20o", "21ree",
                            "22e", "23o", "24ree",
                            "25e", "26o", "27ree",
                            "28e", "29o", "30ree",
                            "31e", "32o", "33ree",
                            "34e", "35o", "36ree",
                            "37e", "38o", "39ree",
                            "40e", "41o", "42ree",
                            "43e", "44o", "45ree",
                            "46e", "47o", "48ree",
                            "one", "two", "three"]))

  end
end

