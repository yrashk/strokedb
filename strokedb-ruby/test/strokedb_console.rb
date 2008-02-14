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

build_config
