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
end