require 'set'

class Hash
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end
  
  def except(*keys)
    reject { |key,| keys.include?(key.to_sym) or keys.include?(key.to_s) }
  end
  
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end

  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end
end

class String
  def ends_with?(suffix)
    suffix = suffix.to_s
    self[-suffix.length, suffix.length] == suffix      
  end
  
  def camel_case
    split('_').map{|e| e.capitalize}.join
  end
  alias :camelize :camel_case
  
  def snake_case
    gsub(/\B[A-Z][^A-Z]/, '_\&').downcase.gsub(' ', '_')
  end
  alias :tableize :snake_case
  
  def demodulize
    gsub(/^.*::/, '')
  end
  
  def constantize
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self
      raise NameError, "#{self.inspect} is not a valid constant name!"
    end
  
    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end
end

class Object
  unless respond_to?(:send!)
    # Anticipating Ruby 1.9 neutering send
    alias send! send
  end
end

module Enumerable
  # Collect an enumerable into sets, grouped by the result of a block. Useful,
  # for example, for grouping records by date.
  #
  # e.g. 
  #
  #   latest_transcripts.group_by(&:day).each do |day, transcripts| 
  #     p "#{day} -> #{transcripts.map(&:class) * ', '}"
  #   end
  #   "2006-03-01 -> Transcript"
  #   "2006-02-28 -> Transcript"
  #   "2006-02-27 -> Transcript, Transcript"
  #   "2006-02-26 -> Transcript, Transcript"
  #   "2006-02-25 -> Transcript"
  #   "2006-02-24 -> Transcript, Transcript"
  #   "2006-02-23 -> Transcript"
  def group_by
    inject({}) do |groups, element|
      (groups[yield(element)] ||= []) << element
      groups
    end
  end if RUBY_VERSION < '1.9'
end

unless :test.respond_to?(:to_proc)
  class Symbol
    # Turns the symbol into a simple proc, which is especially useful for enumerations. Examples:
    #
    #   # The same as people.collect { |p| p.name }
    #   people.collect(&:name)
    #
    #   # The same as people.select { |p| p.manager? }.collect { |p| p.salary }
    #   people.select(&:manager?).collect(&:salary)
    def to_proc
      Proc.new { |*args| args.shift.__send__(self, *args) }
    end
  end
end