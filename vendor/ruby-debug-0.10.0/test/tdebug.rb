#!/usr/bin/env ruby
# -*- Ruby -*-
# This is a hacked down copy of rdebug which can be used for testing

require 'stringio'
require 'rubygems'
require 'optparse'
require "ostruct"

TOP_SRC_DIR = File.join(File.expand_path(File.dirname(__FILE__), "..")) unless 
  defined?(TOP_SRC_DIR)

$: << File.join(TOP_SRC_DIR, "ext")
$: << File.join(TOP_SRC_DIR, "lib")
$: << File.join(TOP_SRC_DIR, "cli")

options = OpenStruct.new(
  'frame_bind'  => false,
  'no-quit'     => false,
  'no-stop'     => false,
  'nx'          => false,
  'post_mortem' => false,
  'script'      => nil,
  'tracing'     => false,
  'verbose_long'=> false,
  'wait'        => false
)

require "ruby-debug"

program = File.basename($0)
opts = OptionParser.new do |opts|
  opts.banner = <<EOB
#{program} #{Debugger::VERSION}
Usage: #{program} [options] <script.rb> -- <script.rb parameters>
EOB
  opts.separator ""
  opts.separator "Options:"
  opts.on("-A", "--annotate LEVEL", Integer, "Set annotation level") do 
    |Debugger::annotate|
  end
  opts.on("-d", "--debug", "Set $DEBUG=true") {$DEBUG = true}
  opts.on("--keep-frame-binding", "Keep frame bindings") do 
    options.frame_bind = true
  end
  opts.on("--no-control", "Do not automatically start control thread") do 
    options.control = false
  end
  opts.on("--no-quit", "Do not quit when script finishes") {
    options.noquit = true
  }
  opts.on("-n", "--no-stop", "Do not stop when script is loaded") {options.nostop = true}
  opts.on("-nx", "Not run debugger initialization files (e.g. .rdebugrc") do
    options.nx = true
  end
  opts.on("-m", "--post-mortem", "Activate post-mortem mode") {options.post_mortem = true}
  opts.on("-I", "--include PATH", String, "Add PATH to $LOAD_PATH") do |path|
    $LOAD_PATH.unshift(path)
  end
  opts.on("-r", "--require SCRIPT", String,
          "Require the library, before executing your script") do |name|
    if name == 'debug'
      puts "ruby-debug is not compatible with Ruby's 'debug' library. This option is ignored."
    else
      require name
    end
  end
  opts.on("--script FILE", String, "Name of the script file to run") do |options.script| 
    unless File.exists?(options.script)
      puts "Script file '#{options.script}' is not found"
      exit
    end
  end
  opts.on("-x", "--trace", "Turn on line tracing") {options.tracing = true}
  ENV['EMACS'] = nil
  opts.separator ""
  opts.separator "Common options:"
  opts.on_tail("--help", "Show this message") do
    puts opts
    exit
  end
  opts.on_tail("--version", 
               "Print the version") do
    puts "ruby-debug #{Debugger::VERSION}"
    exit
  end
  opts.on("--verbose", "Turn on verbose mode") do
    $VERBOSE = true
    options.verbose_long = true
  end
  opts.on_tail("-v", 
               "Print version number, then turn on verbose mode") do
    puts "ruby-debug #{Debugger::VERSION}"
    $VERBOSE = true
  end
end

begin
  if not defined? Debugger::ARGV
    Debugger::ARGV = ARGV.clone
  end
  rdebug_path = File.expand_path($0)
  if RUBY_PLATFORM =~ /mswin/
    rdebug_path += ".cmd" unless rdebug_path =~ /\.cmd$/i
  end
  Debugger::RDEBUG_SCRIPT = rdebug_path
  Debugger::INITIAL_DIR = Dir.pwd
  opts.parse! ARGV
rescue StandardError => e
  puts opts
  puts
  puts e.message
  exit(-1)
end

if ARGV.empty?
  exit if $VERBOSE and not options.verbose_long
  puts opts
  puts
  puts "Must specify a script to run"
  exit(-1)
end
  
# save script name
Debugger::PROG_SCRIPT = ARGV.shift

# install interruption handler
trap('INT') { Debugger.interrupt_last }

# set options
Debugger.wait_connection = false
Debugger.keep_frame_binding = options.frame_bind

# activate debugger
Debugger.start

# activate post-mortem
Debugger.post_mortem if options.post_mortem

# Set up an interface to read commands from a debugger script file.
Debugger.interface = Debugger::ScriptInterface.new(options.script, 
                                                   STDOUT, true)
Debugger.tracing = options.nostop = true if options.tracing

# Make sure Ruby script syntax checks okay.
# Otherwise we get a load message that looks like rdebug has 
# a problem. 
output = `ruby -c #{Debugger::PROG_SCRIPT} 2>&1`
if $?.exitstatus != 0 and RUBY_PLATFORM !~ /mswin/
  puts output
  exit $?.exitstatus 
end
# activate debugger
Debugger.start
# start control thread
Debugger.start_control(options.host, options.cport) if options.control

# load initrc script (e.g. .rdebugrc)
Debugger.run_init_script(StringIO.new) unless options.nx

# run startup script if specified
if options.script
  Debugger.run_script(options.script)
end
# activate post-mortem
Debugger.post_mortem if options.post_mortem
Debugger.tracing = options.nostop = true if options.tracing

# Make sure Ruby script syntax checks okay.
# Otherwise we get a load message that looks like rdebug has 
# a problem. 
output = `ruby -c #{Debugger::PROG_SCRIPT} 2>&1`
if $?.exitstatus != 0 and RUBY_PLATFORM !~ /mswin/
  puts output
  exit $?.exitstatus 
end
if options.noquit
  while true do
    Debugger.stop if Debugger.started?
    begin
      Debugger.debug_load Debugger::PROG_SCRIPT, !options.nostop
    rescue
      print $!.backtrace.map{|l| "\t#{l}"}.join("\n"), "\n"
      print "Uncaught exception: #{$!}\n"
    end
    # FIXME: add status for whether we are interactive or not.
    # if STDIN.tty? and !options.nostop
    if !options.nostop
      print "The program has finished and will be restarted.\n"
    else
      break
    end
  end
else
  Debugger.debug_load Debugger::PROG_SCRIPT, !options.nostop
end
