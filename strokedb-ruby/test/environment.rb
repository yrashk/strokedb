require 'pp'
require "strokedb"
include StrokeDB

Doc = Document

def save!
  StrokeDB.default_store.chunk_storage.sync_chained_storages!
  true
end

def build_config
  StrokeDB::Config.build :default => true, :base_path => (File.dirname(__FILE__) + '/../test/storages/console')
  true
end

def clear!
  FileUtils.rm_rf File.dirname(__FILE__) + '/../test/storages/console'
  build_config
end

def find(*args)
  StrokeDB.default_store.find(*args)
end

def store
  StrokeDB.default_store
end

def h(*args)
  puts %{
    Commands:
    
    clear!      -- Clear the database (will erase all data in console's store)
    save!       -- Save database (if you will quit without it, your changes will not be recorded)
    find <uuid> -- Find document by UUID (example: find "a4430ff1-6cb4-4428-a292-7ab8b77de467")
    
    Aliases:
    
    Doc         -- StrokeDB::Document
    store       -- current store
  }
end

build_config

puts "StrokeDB #{StrokeDB::VERSION} Console"
puts "Type 'h' for help"