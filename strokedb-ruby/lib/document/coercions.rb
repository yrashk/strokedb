module StrokeDB
  module Coercions
    def coerces(slotnames, opts = {})
      opts = opts.stringify_keys
      raise ArgumentError, "coerces should have :to specified" unless opts['to']

      check_condition(opts['if']) if opts['if']
      check_condition(opts['unless']) if opts['unless']
      
      slotnames = [slotnames] unless slotnames.is_a?(Array)
      slotnames.each {|slotname| register_coercion(slotname, opts)}
    end

    private

    def initialize_coercions
      on_set_slot(:coerces) do |doc, slotname, value|
        if coercion = doc.meta["coerces_#{slotname}"] 
          should_call = (!coercion[:if] || evaluate_condition(coercion[:if], doc)) &&
          (!coercion[:unless] || !evaluate_condition(coercion[:unless], doc))
          if should_call 
            case coercion[:to]
            when 'number'
              if value.to_i.to_s == value
                value.to_i
              else
                value
              end
            when 'string'
              value.to_s
            end
          end
        end
      end
    end

    def register_coercion(slotname, opts)
      slotname = slotname.to_s
      to = opts['to'].to_s 

      options_hash = { 
        :slotname => slotname, 
        :if => opts['if'],  
        :unless => opts['unless'],
        :to => to
      }

      # options_hash.merge!(yield(opts)) if block_given?

      coercion_slot = "coerces_#{slotname}"

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!(coercion_slot => { :meta => name }.merge(options_hash))
      end
    end
  end  
end
