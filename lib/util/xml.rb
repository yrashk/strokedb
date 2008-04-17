class Object #:nodoc:
  def to_xml(options = {})
    xml = options[:builder]
    xml.tag!(options[:root], options[:skip_types] ? {} : {:type => self.class.to_s.underscore},to_s)
  end
end
