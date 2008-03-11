if defined? IRB
  IRB.conf[:PROMPT][:CXMP] = { # name of prompt mode
    :PROMPT_C=>nil,
    :PROMPT_I=>nil, :PROMPT_N=>nil, :PROMPT_S=>nil,
    :RETURN => "    # ==> %s\n"        # format to return value
  }
  IRB.conf[:PROMPT_MODE] = :CXMP
end

require 'pp'
require "strokedb"
include StrokeDB

Doc = Document

def save!
  StrokeDB.default_store.chunk_storage.sync_chained_storages!
  true
  "Database has been saved."
end

def build_config
  StrokeDB::Config.build :default => true, :base_path => (File.dirname(__FILE__) + '/../test/storages/console')
  true
end

def clear!
  FileUtils.rm_rf File.dirname(__FILE__) + '/../test/storages/console'
  build_config
  "Database has been wiped out."
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

def reload!
  silence_warnings do
    load "strokedb.rb"
  end
  "Classes reloaded."
end

if ARGV.last.is_a?(String) && File.exists?(ARGV.last+'/config')
  StrokeDB::Config.load(ARGV.last+'/config',true)
  puts "# loading #{ARGV.last}"
  ARGV.pop
else
  build_config
end

puts "StrokeDB #{StrokeDB::VERSION} Console"
puts "Type 'h' for help"
