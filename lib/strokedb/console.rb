require 'irb'
require 'core_ext/string'


module StrokeDB
  
  module Console
    def self.included(klass)
      klass.module_eval do
        
        def setup
          print "Preparing console... "
          @@sandbox = false
          if ARGV.last.is_a? String
            if (@@loc = ARGV.pop) == 'RAM'
              puts '- Using RAM database'
              ::StrokeDB::Config.build :default => true, :storages => [:memory]
            else
              if File.directory?(@@loc)
                print "(using #{@@loc})"
                ::StrokeDB::Config.build :default => true, :base_path => @@loc
              else
                raise "#{@@loc} is not a valid strokedb database!"
              end
            end
          else
            @@loc = 'temp.strokedb'
            ::StrokeDB::Config.build :default => true, :base_path => @@loc
            @@sandbox = true
          end
          @@store = ::StrokeDB::default_store
          @@saved = false
          puts "done!"
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
          FileUtils.rm_rf @@loc
          puts "Database has been wiped out. Exiting."
          exit(1)
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
            - doc             Alias for Document
            - store           Alias for the console's store's object
            ".unindent!)
        end
        
      end
      klass.send(:include, StrokeDB)
      klass.send(:setup)
      
      puts "StrokeDB (v#{::StrokeDB::VERSION}): Interactive console (`help!`)"
      at_exit do klass.clear! if klass.sandbox? && !klass.saved? end
    end # self.included
  end # Console
  
end # StrokeDB