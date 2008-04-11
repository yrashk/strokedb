# extracted from ActiveRecord (http://rubyforge.org/projects/activesupport/)

module Enumerable
  # Collect an enumerable into sets, grouped by the result of a block. Useful,
  # for example, for grouping records by date.
  def group_by
    inject({}) do |groups, element|
      (groups[yield(element)] ||= []) << element
      groups
    end
  end if RUBY_VERSION < '1.9'

  # Map and each_with_index combined.
  def map_with_index
    collected=[]
    each_with_index {|item, index| collected << yield(item, index) }
    collected
  end

  alias :collect_with_index :map_with_index

  def each_consecutive_pair
    first = true
    prev = nil

    each do |val|
      unless first
        yield prev, val
      else
        first = false
      end

      prev = val
    end
  end
end
