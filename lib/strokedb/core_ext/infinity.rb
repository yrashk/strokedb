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

InfiniteString = Class.new(String) do
  def infinite?
    true
  end
end.new.freeze

InfiniteTime = Class.new(Time) do
  def infinite?
    true
  end
end.new.freeze

# Syntactic sugar: sweet aliases for daily use. 
# For use like (SmallestString.."a") in View#find()
#
LargestString = SmallestString = StringInfinity = InfiniteString
LargestTime   = SmallestTime   = TimeInfinity = InfiniteTime
