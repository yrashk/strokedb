core_ext = File.join(File.dirname(__FILE__), "core_ext")

require core_ext + '/string'
require core_ext / :symbol
# require core_ext / :kernel