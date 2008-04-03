module StrokeDB
  module Coercions
    def coerces(slotname, opts = {})
      opts = opts.stringify_keys
      slotname = slotname.to_s
      raise ArgumentError, "coerces should have :to specified" unless opts['to']
      to = opts['to'].to_s 
      
      check_condition(opts['if']) if opts['if']
      check_condition(opts['unless']) if opts['unless']

      options_hash = { 
        :slotname => slotname, 
        :if => opts['if'],  
        :to => to,
        :unless => opts['unless']
      }

      # options_hash.merge!(yield(opts)) if block_given?

      coercion_slot = "coerces_#{slotname}"

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!(coercion_slot => { :meta => name }.merge(options_hash))
      end
    end

    private

    def initialize_coercions
      on_set_slot(:coerces) do |doc, slotname, value|
        if coercion = doc.meta["coerces_#{slotname}"] 
          should_call = (!coercion[:if]     || evaluate_condition(coercion[:if], doc)) &&
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

    def check_condition(condition)
      case condition
      when Symbol, String then return
      else
        unless condition_block?(condition)
          raise(
          ArgumentError,
          "Validations need to be either a symbol, string (to be eval'ed), proc/method, or " +
          "class implementing a static validation method"
          )
        end
      end
    end

    def evaluate_condition(condition, doc)
      case condition
      when Symbol then doc.send(condition)
      when String then eval(condition, doc.send(:binding))
      else
        condition.call(doc)
      end
    end

    def condition_block?(condition)
      condition.respond_to?("call") && (condition.arity == 1 || condition.arity == -1)
    end
  end  
end
