module StrokeDB
  class FileStorage < Storage

    def initialize(options = {})
      @options = options.stringify_keys
      initialize_files
    end

    def save_as_head!(document, timestamp)
      write(document.uuid, document, timestamp)
    end      

    def find(uuid, version=nil, opts = {}, &block)
      uuid_version = uuid + (version ? ".#{version}" : "")
      key = uuid.to_raw_uuid + (version ? version.to_raw_uuid : NIL_UUID.to_raw_uuid)
      if (ptr = @uindex.find(key)) && (ptr != "\x00" * 20) # no way ptr will be zero
        raw_doc = StrokeDB::deserialize(read_at_ptr(ptr))[0]
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
      !!find(uuid,version,:no_instantiation => true)
    end
    # using #include? to match with Array, but #contains sounds much nicer
    alias_method :contains?, :include?

    def head_version(uuid, opts = {})
      if doc = find(uuid,nil,opts.merge({ :no_instantiation => true }))
        doc['version']
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
      position = @archive.insert(StrokeDB::serialize([document,timestamp.counter]))
      ptr = DistributedPointer.pack(@archive.raw_uuid,position)
      uuid = document.raw_uuid
      @uindex.insert(uuid + RAW_NIL_UUID, ptr) if options[:head] || !document.is_a?(VersionedDocument)
      @uindex.insert(uuid + document.version.to_raw_uuid, ptr) unless options[:head]
    rescue ArchiveVolume::VolumeCapacityExceeded	 
      create_new_archive!
    end

    def create_new_archive!
      @archive = ArchiveVolume.new(:path => @options['path'])
      File.open(File.join(@options['path'],'LAST'),'w') do |f|
        f.write(@archive.uuid)
      end
    end

    def last_archive_uuid
      last_filename = File.join(@options['path'],'LAST')
      if File.exists?(last_filename)
        IO.read(last_filename) 
      else 
        uuid = Util.random_uuid
        File.open(last_filename,'w') do |f|
          f.write(uuid)
        end
        uuid
      end
    end

    def read_at_ptr(ptr)
      dptr = DistributedPointer.unpack(ptr)
      volume_uuid = dptr.volume_uuid
      if volume_uuid == @archive.uuid.to_raw_uuid
        @archive.read(dptr.offset)
      else
        archive = ArchiveVolume.new(:path => @options['path'], :uuid => volume_uuid)
        result = archive.read(dptr.offset)
        archive.close!
        result
      end
    end
    
    def path
      @options['path']
    end

    def clear!
      FileUtils.rm_rf(@options['path'])
      initialize_files
    end
    
    def close!
      @archive.close!
      @uindex.close!
    end
      
    
    private
    
    def initialize_files
      FileUtils.mkdir_p(@options['path'])
      @archive = ArchiveVolume.new(:path => @options['path'], :uuid => last_archive_uuid)
      @uindex = FixedLengthSkiplistVolume.new(:path => File.join(@options['path'],'uindex'), :key_length => 32 , :value_length => 20)
    end

  end
end