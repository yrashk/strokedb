module StrokeDB
  class FileChunkStorage
    attr_accessor :path
    def initialize(path)
      @path = path
    end
    
    def each
      @paths = Dir["#{@path}/**"] # FIXME: File.join? Dir.glob special params?
      paths.each do |path|
        raw_chunk = ActiveSupport::JSON.decode(IO.read(path))
        chunk = Skiplist.from_raw(raw_chunk)
        yield chunk
      end
    end

    def save!(chunk)
      
    end
  end
end