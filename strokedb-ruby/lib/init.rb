module StrokeDB
  VERSION = '0.0.2' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')

  # UUID regexp (like 1e3d02cc-0769-4bd8-9113-e033b246b013)
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/

  # document version regexp
  VERSION_RE = UUID_RE

  # so called Nil UUID, should be used as special UUID for Meta meta
  NIL_UUID = "00000000-0000-0000-0000-000000000000" 
  
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
  
  if ENV['DEBUG'] || $DEBUG
    def DEBUG
      yield
    end
  else
    def DEBUG
    end
  end
  
  class NoDefaultStoreError < Exception ; end
end
