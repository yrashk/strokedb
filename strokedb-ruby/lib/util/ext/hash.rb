# extracted and adapted from ActiveRecord (http://rubyforge.org/projects/activesupport/)

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