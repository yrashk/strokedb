require 'rubygems'
require 'activesupport'

(%w[
  util/util 
  data_structures/skiplist
  data_structures/kd_skiplist
  document/slot
  document/document
  sync/diff
  sync/packet
  stores/store
  stores/skiplist_store
  stores/skiplist_store/chunk
  stores/skiplist_store/chunk_storage
  stores/skiplist_store/memory_chunk_storage
  stores/skiplist_store/file_chunk_storage
  ] +
 [RUBY_PLATFORM =~ /java/ ? 'util/java_util' : nil ]).compact.each {|m| require File.dirname(__FILE__) + "/lib/#{m}"}

module StrokeDB
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
end
