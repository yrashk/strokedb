# These are for use in Range arguments for View#find.
# We don't provide correct spaceship operator <=>
# to preserve performance.
#
class Object
  def infinite?
    false
  end
end

class Numeric
  def infinite?
    self.abs == Infinity
  end
end

InfinityString = Class.new(String) do
  def infinite?
    true
  end
end.new.freeze

InfinityTime = Class.new(Time) do
  def infinite?
    true
  end
end.new.freeze

# For use like (SmallestString.."a") in View#find()
#
LargestString = SmallestString = InfinityString
LargestTime   = SmallestTime   = InfinityTime
