class String
  # ==== Parameters
  # o<String>:: The path component to join with the string.
  #
  # ==== Returns
  # String:: The original path concatenated with o.
  #
  # ==== Examples
  #   "lib"/"core_ext" #=> "lib/core_ext"
  def /(o)
    File.join(self, o.to_s)
  end
  
  def underscore
    self.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
end