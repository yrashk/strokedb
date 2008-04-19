$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'benchmark'
include Benchmark 

N = 10
M = 100_000

class A
  def initialize
    @var = Object.new
  end
  def access_ivar
    N.times {
      a = @var
    }
  end
  def access_var
    var = @var
    N.times {
      a = var
    }
  end
end

bm(24) do |x| 
  x.report("Accessing @var") do
    a = A.new
    M.times { a.access_ivar }
  end
  x.report("Accessing var = @var") do
    a = A.new
    M.times { a.access_var }
  end
end
