module Kernel
  def require_one_of(*args)
    if args.first.class == Array
      args = args.first
      original_args = args[1]
    end
    original_args ||= args
    
    begin
      require args.shift
    rescue LoadError
      raise LoadError, "You need one of these gems: #{original_args.join(', ')}" if
        args.empty?
      require_one_of(args, original_args)
    end
    
  end
  
  # Helps to extract arguments for an overloaded methods:
  #   def some_method(*args)
  #     store, name, options = extract(Store, String, Hash, args)
  #   end
  #
  # This method tries to extract arguments according to their type.
  # If the correct type is missing, var is set to nil.
  # If some of the input arguments are not matched, ArgumentError is raised.
  #
  def extract(*template_and_args)
    args = template_and_args.pop
    result = []
        
    args.each do |a|
      unless while t = template_and_args.shift
        t === a and result.push a and break 1 or result.push nil
        end
        raise ArgumentError, "Unexpected argument #{a.inspect} is passed!"
      end
    end
    result + template_and_args.map{ nil }
  end
end