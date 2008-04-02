module StrokeDB
  module Validations

    class ValidationError < StandardError
      attr_reader :document, :meta, :slotname, :on
      
      def initialize(doc,meta,slotname,on,msg)
        @document, @meta, @slotname, @on, @msg = doc,meta,slotname,on,msg
      end
      
      def message
        eval("\"#{@msg}\"")
      end
    end
    
    def validates_presence_of(slotname, opts={}, &block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      message = opts['message'] || '#{meta}\'s #{slotname} should be present on #{on}'

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_presence_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on })
      end
    end

    private 

    def initialize_validations
      before_save(:validates_presence_of) do |doc|
        grep_validations(doc, "validates_presence_of_") do |slotname_to_validate, meta_slotname|
          if validation = doc.meta[meta_slotname] 
            on = validation['on']
            if (on == 'create' && doc.new? && !doc.has_slot?(slotname_to_validate)) ||
               (on == 'update' && !doc.new? && !doc.has_slot?(slotname_to_validate)) ||
               (on == 'save' && !doc.has_slot?(slotname_to_validate))
              raise ValidationError.new(doc,validation['meta'],slotname_to_validate,on,validation['message'])
            end
          end
        end
      end
    end

    def grep_validations(doc, prefix)
      doc.meta.slotnames.each do |slotname|
        if slotname[0..(prefix.length - 1)] == prefix
          yield slotname[prefix.length..-1], slotname
        end
      end
    end

  end  

end
