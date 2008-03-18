require 'readbytes'
module StrokeDB
  class DataVolume

    attr_reader :hindex
    
    def initialize(options = {})
      @options = options.stringify_keys
      FileUtils.mkdir_p @options['path']
      @hindex = Index::H.new(@options)
      initialize_file
    end
    
    def insert!(record)
      serialized=serialize(record)
      if position = @hindex.find(serialized)
        return position
      else
        @file.seek(0, IO::SEEK_END)
        position = @file.pos
        @file.write([serialized.size].pack('N')+serialized)
        @hindex.insert(serialized,position)
        position
      end
    end


    def read(position)
      @file.seek(position)
      deserialize(@file.readbytes(@file.readbytes(4).unpack('N').first))
    end

    def index(record)
      @hindex.find(serialize(record))
    end

    def path
      File.join(@options['path'],'datavol')
    end

    def close!
      @file.close
    end

    private

    def initialize_file
      @file = File.new(path,'a+')
    end

    def serialize(record)
      case record
      when Array
        record = record.map {|v| insert!(v) }
      when Hash
        new_record = {}
        record.each_pair do |k,v|
          new_record[insert!(k)] = insert!(v)
        end
        record = new_record
      end
      StrokeDB::serialize(record)
    end

    def deserialize(record)
      value = StrokeDB::deserialize(record)
      case value
      when Array
        LazyMappingArray.new(value).map_with {|v| read(v) unless v.nil?}.unmap_with{|v| index(v)}
      when Hash
        LazyMappingHash.new(value).map_with {|v| read(v) unless v.nil?}.unmap_with{|v| index(v)}
      else
        value
      end
    end


  end

end