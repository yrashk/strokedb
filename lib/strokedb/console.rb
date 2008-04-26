require 'irb'
require 'core_ext/string'


module StrokeDB
  
  module Console
    RAM_BASE_PATH = '.console-ram.strokedb'
    
    def self.included(klass)
      klass.module_eval do
        
        def setup
          if ARGV.last.is_a? String
            if (@@loc = ARGV.pop) == 'RAM'
              puts 'Using in-memory storage.'
              FileUtils.rm_rf RAM_BASE_PATH
              ::StrokeDB::Config.build :default => true, :storages => [:memory], :base_path => RAM_BASE_PATH
            else
              puts "Using #{@@loc} storage."
              ::StrokeDB::Config.build :default => true, :base_path => @@loc
            end
          else
            @@loc = '.console.strokedb'
            ::StrokeDB::Config.build :default => true, :base_path => @@loc
          end
          @@store = ::StrokeDB::default_store
          @@saved = false
        end
        
        def save!
          @@store.storage.sync_chained_storages!
          @@saved = true
          @@store
        end
        def saved?
          @@saved
        end

        def clear!
          if @@loc == 'RAM'
            FileUtils.rm_rf RAM_BASE_PATH
          else
            FileUtils.rm_rf @@loc
          end
          setup
          "Database has been wiped out."
        end

        def find(*args)
          @@store.find(*args)
        end

        def store
          @@store
        end
        
        def sandbox?
          @@sandbox
        end
        
        def reload!
          silence_warnings do
            load "strokedb.rb"
          end
          StrokeDB
        end
        
        def help!
          puts ("
            - save!           Save the console's store (by default, a file in your current directory named console.strokedb)
            - clear!          Drop the console's store (destructive, and launches you out of the session)
            - find <uuid>     Find document by UUID in the console's store (example: find 'a4430ff1-6cb4-4428-a292-7ab8b77de467')
            - Doc             Alias for Document
            - store           Alias for the console's store's object
            ".unindent!)
        end
        
      end
      klass.send(:include, StrokeDB)
      klass.send(:setup)
      
      puts "StrokeDB #{::StrokeDB::VERSION} (help! for more info)"
    end # self.included
  end # Console
  Doc = Document
end # StrokeDB
