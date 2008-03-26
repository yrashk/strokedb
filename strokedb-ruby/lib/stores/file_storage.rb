module StrokeDB
  class FileStorage < Storage

    def initialize(options = {})
      @options = options.stringify_keys
      @archive = ArchiveVolume.new(:path => @options['path'], :uuid => last_archive_uuid)
      @uindex = FixedLengthSkiplistVolume.new(:path => File.join(@options['path'],'uindex'), :key_length => 32 , :value_length => 20)
    end

    def save_as_head!(document, timestamp)
      write(document.uuid, document, timestamp)
    end      

    def find(uuid, version=nil, opts = {})
      uuid_version = uuid + (version ? ".#{version}" : "")
      key = uuid.to_raw_uuid + (version ? version.to_raw_uuid : NIL_UUID.to_raw_uuid)
      raw_doc = StrokeDB::deserialize(@uindex.find(key))[0]
      unless opts[:no_instantiation]
        doc = Document.from_raw(opts[:store], raw_doc.freeze) # FIXME: there should be a better source for store (probably)
        doc = Document.from_raw(self,raw_doc.freeze)
        doc.extend(VersionedDocument) if version
        doc
      else
        raw_doc
      end
    end

    def exists?(uuid,version=nil)
      !!find(uuid,version,:no_instantiation => true)
    end

    def head_version(uuid)
      if doc = find(uuid,nil, :no_instantiation => true)
        doc['version']
      end	 
    end

    def each(options = {})
      after = options[:after_timestamp]
      include_versions = options[:include_versions]
      @container.each do |key, value|
        next if after && (value[1] <= after)
        if uuid_match = key.match(/^#{UUID_RE}$/) || (include_versions && uuid_match = key.match(/#{UUID_RE}./) )
          yield value[0]
        end
      end
    end

    def perform_save!(document, timestamp)
      position = @archive.insert(StrokeDB::serialize([document,timestamp.counter]))
      ptr = DistributedPointer.new(@archive.uuid,position).pack
      @uindex.insert(document.uuid.to_raw_uuid + NIL_UUID.to_raw_uuid, ptr)
      @uindex.insert(document.uuid.to_raw_uuid + document.version.to_raw_uuid, ptr)
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
      FileUtils.mkdir_p(@options['path'])
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


  end
end