# extracted and adapted from ActiveRecord (http://rubyforge.org/projects/activesupport/)

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

  def tableize
    words = snake_case.split('_')
    words.last.replace words.last.plural
    words.join('_')
  end

  def demodulize
    gsub(/^.*::/, '')
  end

  def modulize
    return '' unless include?('::') && self[0,2] != '::'
    self.gsub(/^(.+)::(#{demodulize})$/,'\\1')
  end

  def constantize
    if /^meta:/ =~ self
      return StrokeDB::META_CACHE[Meta.make_uuid_from_fullname(self)]
    end
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self
      raise NameError, "#{self.inspect} is not a valid constant name!"
    end
    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end
  
  def /(o)
    File.join(self, o.to_s)
  end
  
  def unindent!
    self.gsub!(/^\n/, '').gsub!(/^#{self.match(/^\s*/)[0]}/, '')
  end
  
  def underscore
    self.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
  
  def lines
    self.split("\n").size
  end
end