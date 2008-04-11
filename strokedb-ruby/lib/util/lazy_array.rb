module StrokeDB
  # Lazy loads items from array.
  #
  # Lazy arrays are backed by Proc returning regular array
  # on first call retrieving it from @load_with_proc.
  #
  # Example:
  #
  #   ary = LazyArray.new.load_with { Time.now.to_s.split(/\s/) }
  #
  # On first attempt to access <tt>ary</tt> (including <tt>inspect</tt>) it will
  # evaluate load_with's Proc and update own content with its result:
  #
  #   ary
  #     # ==> ["Mon", "Mar", "17", "10:35:52", "+0200", "2008"]
  #
  class LazyArray < BlankSlate
    def initialize(*args)
      @load_with_proc = proc {|v| v}
      @array = Array.new(*args)
    end

    # Proc to execute lazy loading
    def load_with(&block)
      @load_with_proc = block
      self
    end

    # Make it look like array for outer world
    def class
      Array
    end

    def method_missing sym, *args, &blk
      if @array.respond_to? sym
        load!
        @array.__send__ sym, *args, &blk
      else
        super
      end
    end

    private

    def load!
      if @load_with_proc
        @array.clear
        @array.concat @load_with_proc.call(@array)
        @load_with_proc = nil
      end
    end

  end
end
