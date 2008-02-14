require "strokedb"
include StrokeDB
StrokeDB::Config.build :default => true, :base_path => 'test/storages/console'
Doc = Document
