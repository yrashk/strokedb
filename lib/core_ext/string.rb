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
end