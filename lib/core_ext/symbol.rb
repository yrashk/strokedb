class Symbol
  # ==== Parameters
  # o<String>:: The path component to join with the symbol.
  #
  # ==== Returns
  # String:: The original path concatenated with o.
  #
  # ==== Examples
  #   :lib / :core_ext #=> "lib/core_ext"
  def /(o)
    File.join(self.to_s, o.to_s)
  end
end