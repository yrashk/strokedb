require 'rubygems'
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift( File.expand_path(File.join(File.dirname(__FILE__), 'strokedb')) ).uniq!
require 'strokedb/core_ext'
require File.join(File.dirname(__FILE__), '/../vendor/rbmodexcl/rbmodexcl')
require_one_of 'json', 'json_pure'

require 'set'
require 'fileutils'



module StrokeDB
  # Version:
        MAIN = 0
       MAJOR = 0
       MINOR = 2
  PATCHLEVEL = 2
  
  VERSION = [MAIN.to_s, MAJOR.to_s, MINOR.to_s, PATCHLEVEL.to_s].join('.')
  VERSION_STRING = VERSION + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  
  # Coverage threshold - bump this float anytime your changes increase the spec coverage
  # DO NOT LOWER THIS NUMBER. EVER.
  COVERAGE = 92

  # UUID regexp (like 1e3d02cc-0769-4bd8-9113-e033b246b013)
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/

  # document version regexp
  VERSION_RE = UUID_RE
  
  # XML Schema time format
  # Time.now.xmlschema(6)
  #    #=> "2008-04-27T23:39:09.920288+04:00"
  # Time.xmlschema("2008-04-27T23:39:09.920288+04:00")
  #    #=> Sun Apr 27 19:39:09 UTC 2008
  XMLSCHEMA_TIME_RE = /\A\s*(-?\d+)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(\.\d*)?(Z|[+-]\d\d:\d\d)?\s*\z/i
  
  # STROKEDB NSURL
  STROKEDB_NSURL = "http://strokedb.com/"
  
  # so called Nil UUID
  NIL_UUID                      = "00000000-0000-0000-0000-000000000000"
  RAW_NIL_UUID                  = "\x00" * 16
  
  class <<self
    def default_store
      StrokeDB.default_config.stores[:default] rescue nil
    end
    def default_store=(store)
      cfg = Config.new
      cfg.stores[:default] = store
      StrokeDB.default_config = cfg
    end
  end

  if ENV['DEBUG'] || $DEBUG
    def DEBUG
      yield
    end
  else
    def DEBUG
    end
  end

  OPTIMIZATIONS = []
  OPTIMIZATIONS << :C    unless RUBY_PLATFORM =~ /java/
  OPTIMIZATIONS << :Java if     RUBY_PLATFORM =~ /java/

  class NoDefaultStoreError < Exception ; end
end

require 'strokedb/nsurl'

require 'strokedb/util'
require 'strokedb/document'
require 'strokedb/config'
require 'strokedb/data_structures'
require 'strokedb/volumes'
require 'strokedb/sync'
require 'strokedb/index'
require 'strokedb/transaction'
require 'strokedb/stores'
require 'strokedb/views'