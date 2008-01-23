require 'rubygems'
require 'activesupport'

['util','skiplist','slot','document','file_store','packet','replica',
 RUBY_PLATFORM =~ /java/ ? 'java_util' : nil ].compact.each {|m| require File.dirname(__FILE__) + "/lib/#{m}"}

module StrokeDB
  VERSION = '0.1' + (RUBY_PLATFORM =~ /java/ ? 'j' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
end
