require 'rubygems'
require 'activesupport'

require 'lib/util'
require 'lib/skiplist'
require 'lib/slot'
require 'lib/document'
require 'lib/file_store'
require 'lib/replica'

require 'lib/java_util' if RUBY_PLATFORM =~ /java/

module StrokeDB
  VERSION = '0.1' + (RUBY_PLATFORM =~ /java/ ? 'j' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
end
