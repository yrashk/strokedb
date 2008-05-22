module StrokeDB
  class FileViewStorage < ViewStorage
    
    def initialize(options = {})
      # TODO: find out whether the view indexfile exists and read
      #       its options
      options = options.stringify_keys
      
      path    = options['path']
      maxsize = options['max_log_size']
      silent  = options['silent']
      
      @volume_options = {:path => path, :max_log_size => maxsize, :silent => silent}
      
      @list = SkiplistVolume.new(@volume_options)
    end
    
    def clear!
      @list = SkiplistVolume.new(@volume_options)
    end
  end
end
