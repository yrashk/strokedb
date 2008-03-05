module StrokeDB

  module Validations

    class ValidationError < Exception
      attr_reader :document, :meta, :slotname
      def initialize(doc,meta,slotname,msg)
        @document, @meta, @slotname, @msg = document,meta,slotname,msg
      end
      def message
        eval("\"#{@msg}\"")
      end
    end
    

    def validates_presence_of(slotname,opts={},&block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      message = opts['message'] || '#{meta}\'s #{slotname} should be present'
      on = (opts['on'] || 'save').to_s.downcase

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_presence_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on })
      end
    end 
    
    private 
    
    def initialize_validations
      before_save(:validates_presence_of) do |doc|
        presence_validations = doc.meta.slotnames.grep(/^validates_presence_of_/).map{|v| v.gsub(/^validates_presence_of_(.+)/,'\\1')}
        presence_validations.each do |slotname_to_validate|
          if validation=doc.meta["validates_presence_of_#{slotname_to_validate}"] 
            if validation['on'] == 'save' && !doc.has_slot?(slotname_to_validate)
              raise ValidationError.new(doc,validation['meta'],slotname_to_validate,validation['message'])
            end
            if validation['on'] == 'create' && doc.new? && !doc.has_slot?(slotname_to_validate)
              raise ValidationError.new(doc,validation['meta'],slotname_to_validate,validation['message'])
            end
          end
        end
      end
    end
    
  end  


end
