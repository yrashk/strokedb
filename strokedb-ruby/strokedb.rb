require 'rubygems'
require 'activesupport'

(%w[
  util 
  skiplist
  kd_skiplist
  slot
  document
  diff
  packet
  store
  skiplist_store
  chunk
  chunk_storage
  memory_chunk_storage
  file_chunk_storage
  ] +
 [RUBY_PLATFORM =~ /java/ ? 'java_util' : nil ]).compact.each {|m| require File.dirname(__FILE__) + "/lib/#{m}"}

module StrokeDB
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
end
