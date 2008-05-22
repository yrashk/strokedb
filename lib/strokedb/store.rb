module StrokeDB

  StoreInfo = Meta.new

  class Store
    include Enumerable
    attr_accessor :storage, :index_store, :uuid
    attr_reader :timestamp

    def initialize(options = {})
      @options = options.stringify_keys
      @storage = @options['storage']
      @index_store = @options['index']
      initialize_files
      autosync! unless @options['noautosync']
      raise "Missing chunk storage" unless @storage
    end

    def find(uuid, version=nil, opts = {}, &block)
      @storage.find(uuid,version,opts.merge(:store => self),&block)
    end

    def search(*args)
      return [] unless @index_store
      @index_store.find(*args)
    end

    def include?(uuid,version=nil)
      @storage.include?(uuid,version)
    end
    alias_method :contains?, :include?

    def head_version(uuid)
      @storage.head_version(uuid,{ :store => self })
    end

    def save!(doc)
      next_timestamp!
      storage.save!(doc, timestamp)
      
      update_views!(doc)
      
      # TODO: remove this shit 
      if @index_store
        if doc.previous_version
          raw_pdoc = find(doc.uuid,doc.previous_version,:no_instantiation => true)
          pdoc = Document.from_raw(self,raw_pdoc.freeze,:skip_callbacks => true)
          pdoc.extend(VersionedDocument)
          @index_store.delete(pdoc)
        end
        @index_store.insert(doc)
        @index_store.save!
      end
    end  

    def save_as_head!(doc)
      @storage.save_as_head!(doc,timestamp)
      update_views!(doc)
    end



    def each(options = {},&block)
      @storage.each(options.merge(:store => self),&block)
    end

    def next_timestamp!
      @timestamp = timestamp.next
      update_timestamp!
      @timestamp
    end

    def uuid
      return @uuid if @uuid
      @uuid = Util.random_uuid
    end


    def document
      find(uuid) || StoreInfo.create!(self, :uuid => uuid)
    end

    def inspect
      "#<Store #{uuid}>"
    end

    def autosync!
      @autosync_mutex ||= Mutex.new
      @autosync = nil if @autosync && !@autosync.status
      @stop_autosync = false
      at_exit do
         stop_autosync! unless @stop_autosync
       end
      @autosync ||= Thread.new do 
        until @stop_autosync
          @autosync_mutex.synchronize { storage.sync_chained_storages! }
          sleep(1)
        end
      end
    end
    
    def autosync?
      @autosync && !@autosync.status
    end

    def stop_autosync!
      if @autosync_mutex
        @autosync_mutex.synchronize do
          unless @stop_autosync
            @stop_autosync = true
            storage.sync_chained_storages! 
          end
        end
      end
    end

    def path
      @options['path']
    end


    private

    def initialize_files
      FileUtils.mkdir_p(path)
      uuid_file = File.join(path,'UUID')
      timestamp_file = File.join(path,'TIMESTAMP')

      if File.exists?(uuid_file)
        @uuid = IO.read(uuid_file)
      else
        File.open(uuid_file,'w') do |f|
          f.write(uuid)
        end
      end
      if File.exists?(timestamp_file)
        @timestamp = LTS.new(IO.read(timestamp_file).to_i,uuid)
      else
        @timestamp = LTS.zero(uuid)
        update_timestamp!
      end
    end

    def update_timestamp!
      timestamp_file = File.join(path,'TIMESTAMP')
      File.open(timestamp_file,'w') do |f|
        f.write(timestamp.counter)
      end        
    end

  end
end

require 'stores/chainable_storage'
module StrokeDB
  class Storage
    include ChainableStorage

    attr_accessor :authoritative_source

    def initialize(opts={})
    end

  end
end