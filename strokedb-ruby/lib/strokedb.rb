module StrokeDB
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
  VERSION_RE = /([a-f0-9]{64})/
  NIL_UUID = "00000000-0000-0000-0000-000000000000" # so called Nil UUID, should be used as special UUID for Meta meta
  
  class <<self
    def default_store
      StrokeDB.default_config.stores[:default]
    end
  end
  
  class NoDefaultStoreError < Exception ; end
  
end
