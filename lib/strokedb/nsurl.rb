Module.module_eval do
  
  def self.reset_nsurls
    @@nsurls = {}
    ::Module.nsurl ''
    ::StrokeDB.nsurl StrokeDB::STROKEDB_NSURL    
  end
  def self.find_by_nsurl(url)
    @@nsurls[url]
  end
  
  def nsurl(url = nil)
    return @nsurl unless url
    @@nsurls ||= {}
    mod = @@nsurls[url]
    raise ArgumentError, "nsurl #{url.inspect} is already referenced by #{mod.inspect} module" if mod && mod != self
    @@nsurls.delete(url)
    @@nsurls[url] = self
    @nsurl = url
  end
  
end

Module.reset_nsurls