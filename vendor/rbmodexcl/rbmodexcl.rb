if defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
  require File.join(File.dirname(__FILE__),'rbxmodexcl')
else
  require File.join(File.dirname(__FILE__),'mrimodexcl')
end