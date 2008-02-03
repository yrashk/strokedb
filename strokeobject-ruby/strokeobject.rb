require 'strokedb'

module Stroke
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  NIL_UUID = "00000000-0000-0000-0000-000000000000" # so called Nil UUID, should be used as special UUID for Meta meta

  class <<self
    def default_store
      StrokeDB.default_config.stores[:default]
    end
  end
  
  class NoDefaultStoreError < Exception ; end
  
end

%w(object meta).each do |filename|
  require File.expand_path(File.dirname(__FILE__) + '/lib/' + filename)
end
