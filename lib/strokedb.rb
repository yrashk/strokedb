require 'rubygems'
$LOAD_PATH.unshift( File.expand_path(File.join(File.dirname(__FILE__), 'strokedb')) ).uniq!
require 'strokedb/core_ext'

require_one_of 'json', 'json_pure'

require 'set'
require 'fileutils'

module StrokeDB
  # Version:
        MAIN = 0
       MAJOR = 0
       MINOR = 2
  PATCHLEVEL = 1
  
  VERSION = [MAIN.to_s, MAJOR.to_s, MINOR.to_s, PATCHLEVEL.to_s].join('.')
  VERSION_STRING = VERSION + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  
  # Coverage threshold - bump this float anytime your changes increase the spec coverage
  # DO NOT LOWER THIS NUMBER. EVER.
  COVERAGE = 87.9

  # UUID regexp (like 1e3d02cc-0769-4bd8-9113-e033b246b013)
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/

  # document version regexp
  VERSION_RE = UUID_RE

  RAW_NIL_UUID                  = "\x00" * 16
  # following are special UUIDs used by StrokeDB

  # so called Nil UUID, should be used as special UUID for Meta meta
  NIL_UUID                      = "00000000-0000-0000-0000-000000000000"

  # UUID used for DeletedDocument meta
  DELETED_DOCUMENT_UUID         = 'e5e0ef20-e10f-4269-bff3-3040a90e194e'

  # UUID used for StoreInfo meta
  STORE_INFO_UUID               = "23e11d2e-e3d3-4c24-afd2-b3316403dd03"

  # UUID used for Diff meta
  DIFF_UUID                     = "5704bd39-4a01-405e-bc72-3650ddd89ca4"

  # UUID used for SynchronizationReport meta
  SYNCHRONIZATION_REPORT_UUID   = "8dbaf160-addd-401a-9c29-06b03f70df93"
  
  # UUID used for SynchronizationConflict meta
  SYNCHRONIZATION_CONFLICT_UUID = "36fce59c-ee3d-4566-969b-7b152814a314"

  # UUID used for View meta
  VIEW_UUID                     = "ced0ad12-7419-4db1-a9f4-bc35e9b64112"

  # UUID used for ViewCut meta
  VIEWCUT_UUID                  = "2975630e-c877-4eab-b86c-732e1de1adf5"


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

require 'strokedb/util'
require 'strokedb/document'
require 'strokedb/config'
require 'strokedb/data_structures'
require 'strokedb/volumes'
require 'strokedb/sync'
require 'strokedb/index'
require 'strokedb/view'
require 'strokedb/transaction'
require 'strokedb/stores'