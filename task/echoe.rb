class Echoe
  def self.taskify(&block)
    
    begin
      %w|echoe spec
        spec/rake/spectask rake/rdoctask spec/rake/verify_rcov|.each {|d| require d}
      
      yield block
      
    rescue LoadError
      puts "(You need to install the echoe and rspec gems if you wish to" +
           " perform meta-gem operations, such as installing from source or" +
           " running specs)"
    end
    
  end
end