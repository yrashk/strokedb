module StrokeDB
  class MemoryStorage < Storage
    
    def initialize(options = {})
    	@options = options.stringify_keys
    	clear!
    end
    
    def save_as_head!(document, timestamp)
      save!(document,timestamp, :head => true)
		end      
    
    def find(uuid, version=nil, opts = {},&block)
      uuid_version = uuid + (version ? ".#{version}" : "")
      unless raw_doc = read(uuid_version)
        authoritative_source.find(uuid,version,opts,&block) if authoritative_source
      else
        unless opts[:no_instantiation]
          doc = Document.from_raw(opts[:store], raw_doc.freeze, &block) # FIXME: there should be a better source for store (probably)
          doc.extend(VersionedDocument) if version
          doc
        else
          raw_doc
        end
      end
    end
    
    def include?(uuid,version=nil)
      uuid_version = uuid + (version ? ".#{version}" : "")
      !@container.find(uuid_version).nil?
    end
    alias_method :contains?, :include?

    def head_version(uuid, opts = {})
      if doc = find(uuid,nil, opts)
      	 doc.version
      end	 
    end
 		
 		def each(options = {})
      after = options[:after_timestamp]
      include_versions = options[:include_versions]
      @container.each do |key, value|
          next if after && (value[1] <= after)
          if uuid_match = key.match(/^#{UUID_RE}$/) || (include_versions && uuid_match = key.match(/#{UUID_RE}./) )
            yield Document.from_raw(options[:store],value[0])
          end
      end
 		end

    def perform_save!(document, timestamp, options = {})
      uuid = document.uuid
      version = document.version
      raw_document = document.to_raw
      uuid_version = uuid + (version ? ".#{version}" : "")
      write(uuid, raw_document, timestamp) if options[:head] || !document.is_a?(VersionedDocument)
      write(uuid_version, raw_document, timestamp) unless options[:head]
    end

    def clear!
      @container = SimpleSkiplist.new
    end

    def close!
    end
    
    private

    def read(key)
      if record = @container.find(key)
      	 record.first
      end
    end
        
    def write(key, document, timestamp)
      @container.insert(key, [document, timestamp.counter])
    end
    
  end
end