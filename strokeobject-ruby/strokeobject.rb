require 'strokedb'

module Stroke
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  NIL_UUID = "00000000-0000-0000-0000-000000000000" # so called Nil UUID, should be used as special UUID for Meta meta

  #
  # Stroke.default_store accessor (should be thread-safe)
  # Stroke.default_config accessor (should be thread-safe)
  #
  class <<self
    def default_store
      Thread.current['StrokeObject.default_store']
    end
    def default_store=(store)
      Thread.current['StrokeObject.default_store'] = store
    end
  end
  
  class NoDefaultStoreError < Exception ; end
  
end

%w(object meta).each do |filename|
  require File.expand_path(File.dirname(__FILE__) + '/lib/' + filename)
end
