require 'rubygems'
require 'activesupport'

require 'lib/util'
require 'lib/slot'
require 'lib/document'
require 'lib/file_store'
require 'lib/replica'

require 'lib/java_util' if RUBY_PLATFORM =~ /java/

module StrokeDB
  VERSION = '0.1' + (RUBY_PLATFORM =~ /java/ ? 'j' : '')
end
