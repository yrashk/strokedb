# extracted and adapted from ActiveSupport (http://rubyforge.org/projects/activesupport/)

class Fixnum
  def multiple_of?(number)
    self % number == 0
  end
  
  def even?
    multiple_of? 2
  end
  
  def odd?
    !even?
  end
end

