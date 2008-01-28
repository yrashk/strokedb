require 'rubygems'
require 'activesupport'

class SmartassLoader
  def initialize(pattern)
    @pattern = pattern
    @req_paths = {}
  end
  def require!
    paths = Dir[@pattern].select do |p| 
      (p !~ /\/java_/ || RUBY_PLATFORM =~ /java/) && p =~ /\.rb$/
    end.sort.map do |p|
      File.expand_path(File.dirname(__FILE__) + "/" + p)
    end
    require_rest_paths(paths)
  end
  def require_rest_paths(paths)
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
      rescue NameError
        puts "Not resolved: #{p}" if ENV["DEBUG"]
        broken_paths.push p
      end
    end
    # Stack grows...
    require_rest_paths(broken_paths) unless broken_paths.empty? 
  end
end

SmartassLoader.new("lib/**/*").require!

module StrokeDB
  VERSION = '0.0.1' + (RUBY_PLATFORM =~ /java/ ? '-java' : '')
  UUID_RE = /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/
  VERSION_RE = /([a-f0-9]{64})/
end
