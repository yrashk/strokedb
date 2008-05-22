
require 'benchmark'
include Benchmark

N = 1000_000

test = ARGV[0].to_i || 1

case test
when 1
  bm(32) do |x| 
    x.report("Inline string literals") do
      N.times do 
        [] << "blah-blah1" << "blah-blah2" << "blah-blah3" << "blah-blah4" << "blah-blah5" << "blah-blah6" << "blah-blah7" << "blah-blah8"
      end
    end
    x.report("Constantized string literals") do
      S1 = "blah-blah1"
      S2 = "blah-blah2"
      S3 = "blah-blah3"
      S4 = "blah-blah4"
      S5 = "blah-blah5"
      S6 = "blah-blah6"
      S7 = "blah-blah7"
      S8 = "blah-blah8"
      N.times do 
        [] << S1 << S2 << S3 << S4 << S5 << S6 << S7 << S8
      end
    end
  end
when 2
  bm(32) do |x| 
    x.report("Inline string literals (big)") do
      N.times do 
        [] << %{The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement. The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement.} << %{The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement. The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement.}
        
      end
    end
    x.report("Constantized string literals (big)") do
      S1 = %{The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement. The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement.}
      S2 = %{The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement. The body of knowledge modeled by a collection of statements may be subjected to reification, in which each statement (that is each triple subject-predicate-object altogether) is assigned a URI and treated as a resource about which additional statements can be made, as in "Jane says that John is the author of document X". Reification is sometimes important in order to deduce a level of confidence or degree of usefulness for each statement.}
      N.times do 
        [] << S1 << S2
      end
    end
  end  
end

