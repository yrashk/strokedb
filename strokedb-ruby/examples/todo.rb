#! /usr/bin/env ruby
$:.unshift File.dirname(__FILE__) + "/.."
require "strokedb"

StrokeDB::Config.build :default => true, :base_path => '.todo.strokedb'

TodoList = StrokeDB::Meta.new do
  on_initialization do |list|
    list.items = [] unless list[:items]
  end
  def to_s
    s = "#{name}:\n"
    items.each do |item|
      s << "  #{item}"
    end
    s
  end
end

TodoItem = StrokeDB::Meta.new do
  def done!
    self.done = true
    save!
  end
  def to_s
    status = done ? "X" : " "
    "[#{status}] #{description}"
  end
end

def add_issue(prefix,description)
  todo_list = TodoList.find_or_create(:name => prefix)
  todo_item = TodoItem.create!(:description => description, :done => false)
  todo_list.items << todo_item
  todo_list.save!
end

def complete_issue(prefix,description)
  todo_list = TodoList.find_or_create(:name => prefix)
  return unless todo_list
  if item = todo_list.items.find {|item| item.description == description }
    item.done!
  else 
    puts "No such item found"
  end
end

def list_issues
  todo_lists = TodoList.find
  return [] if todo_lists.empty?
  todo_lists.each { |list| puts list }
end

def extract_prefix_item(str)
  _, prefix, _, item = str.match(/(^\[(.*)\])?(.+)/).to_a
  prefix ||= "[Main]"
  prefix.gsub!(/(^\[|\]$)/,'')
  item.lstrip!
  [prefix,item]
end

if ARGV.empty?
  if list_issues.empty?
    puts "Type --help for program help"
  end
  exit
end

if ARGV.first.downcase == "--help"
  puts %{
    Usage: todo Do this                          Add item to 'Main' list
           todo [project] Do that                Add item to 'project' list
           todo -d Do this                       Complete item in 'Main' list
           todo -d [project] Do that             Complete item in 'project' lis
           todo                                  List all items
           todo --help                           This help message
  }
  exit
end

unless ARGV.first.downcase == "-d"
  prefix,item = extract_prefix_item(ARGV.join(' '))
  add_issue(prefix,item)
else
  args = ARGV
  args.shift
  prefix,item = extract_prefix_item(args.join(' '))
  complete_issue(prefix,item)
end

StrokeDB.default_store.chunk_storage.sync_chained_storages!

