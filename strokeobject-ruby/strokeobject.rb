require 'strokedb'

%w(object meta).each do |filename|
  require File.expand_path(File.dirname(__FILE__) + '/lib/' + filename)
end

module Stroke
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  NIL_UUID = "00000000-0000-0000-0000-000000000000"


  #
  # Stroke.default_store accessor (should be thread-safe)
  #
  class <<self
    def default_store
      Thread.current['StrokeObject.default_store']
    end
    def default_store=(store)
      Thread.current['StrokeObject.default_store'] = store
    end
  end

end

