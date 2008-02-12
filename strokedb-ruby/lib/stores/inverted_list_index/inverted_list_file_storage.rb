module StrokeDB
  class InvertedListFileStorage
    # TODO: 
    # include ChainableStorage

    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def find_list
      read(file_path)
    end
    
    def clear!
      FileUtils.rm_rf @path
    end
    
    def save!(list)
      FileUtils.mkdir_p @path
      write(file_path, list)
    end
    
  private

    def read(path)
      return InvertedList.new unless File.exist?(path)
      raw_list = StrokeDB.deserialize(IO.read(path))
      list = InvertedList.new
      # TODO: Optimize!
      raw_list.each do |k, vs|
        vs.each do |v|
          list.insert_attribute(k, v)
        end
      end
      list
    end
    
    def write(path, list)
      raw_list = {}
      # TODO: Optimize!
      list.each do |n|
        raw_list[n.key] = n.values
      end
      File.open path, "w+" do |f|
        f.write StrokeDB.serialize(raw_list)
      end
    end
  
    def file_path
      "#{@path}/INVERTED_INDEX"
    end
  end
end
