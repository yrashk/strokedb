ruby_debug_path     = File.dirname(__FILE__) + '/vendor/ruby-debug-0.10.0/cli/'

if ENV["DEBUGGER"]
  if File.exist?(ruby_debug_path)
    $:.unshift( ruby_debug_path )
  else
    puts "Using ruby-debug gem"
    require 'rubygems'
  end

  require 'ruby-debug'
  ENV["DEBUG"] = 1
else
  module Kernel
    def debugger; end
  end
end

require 'rubygems'
begin
  require 'json'
rescue LoadError
  begin
    require 'json_pure'
  rescue LoadError
    raise LoadError, 'Could not find json or json_pure'
  end
end

require 'set'
require 'fileutils'
require 'drb'
require 'drb/acl'
require 'drb/unix'

class SmartassLoader
  def initialize(pattern)
    @pattern = pattern
    @req_paths = {}
  end

  def require!
    paths = Dir[File.dirname(__FILE__) + "/" + @pattern].select do |p|
      (p !~ /\/java_/ || RUBY_PLATFORM =~ /java/) && p =~ /\.rb$/
    end.sort.map do |p|
      File.expand_path(p)
    end
    require_rest_paths(paths)
  end

  def require_rest_paths(paths, i = 0)
    ENV['DEBUG'] = "1"  if i == 10
    ENV.delete('DEBUG') if i == 20
    broken_paths = []
    paths.each do |p|
      begin
        if @req_paths[p]
          load p
          puts "Resolved: #{p}" if ENV["DEBUG"]
        else
          @req_paths[p] = 1
          require p
        end
      rescue NameError => e
        puts "Not resolved: #{p}" if ENV["DEBUG"]
        puts e if ENV["DEBUG"]
        broken_paths.push p
      end
    end
    # Stack grows...
    require_rest_paths(broken_paths, i + 1) unless broken_paths.empty?
  end
end

SmartassLoader.new("lib/**/*").require!