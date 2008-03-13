class Object #:nodoc:
  def to_xml(options = {})
    xml = options[:builder]
    xml.tag!(options[:root], {:type => self.class.to_s.underscore},to_s)
  end
end
