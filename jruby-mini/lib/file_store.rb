require 'lib/store'

module StrokeDB
  class FileStore < Store
    attr_reader :path

    def find(uuid,version=nil)
      return nil unless exists?(uuid)
      json = IO.read(filename(uuid,version))
      load_doc(uuid,json)
    end

    def initialize(path)
      @path = path
    end

    def exists?(uuid)
      File.exists?(filename(uuid))
    end

    def last_version(uuid)
      if exists?(uuid)
        json = IO.read(filename(uuid))
        ActiveSupport::JSON.decode(json)['__version__']
      end
    end

    def save!(doc)
      FileUtils.mkdir_p File.dirname(filename(doc.uuid))
      File.open filename(doc.uuid), "w+" do |f|
        f.write doc.to_json
      end
      File.open filename(doc.uuid,doc[:__version__]), "w+" do |f|
        f.write doc.to_json
      end
    end

  private

    def filename(uuid,version=nil)
      uuid_s = uuid.to_s
      File.join(path,[uuid_s[0,2], uuid_s[2,2], uuid_s[4,2], uuid_s.slice(6,30).gsub('-','')].join('/') + (version ? ".#{version}" : "") )
    end
  end
end