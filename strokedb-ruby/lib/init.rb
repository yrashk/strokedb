module StrokeDB
  VERSION = '0.0.2' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
  VERSION_RE = UUID_RE
  NIL_UUID = "00000000-0000-0000-0000-000000000000" # so called Nil UUID, should be used as special UUID for Meta meta
  
  class <<self
    def default_store
      StrokeDB.default_config.stores[:default] rescue nil
    end
    def default_store=(store)
      cfg = Config.new
      cfg.stores[:default] = store
      StrokeDB.default_config = cfg
    end
  end

  
  class NoDefaultStoreError < Exception ; end
  
end
