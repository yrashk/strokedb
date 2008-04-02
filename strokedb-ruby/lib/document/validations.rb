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
    

    def validates_presence_of(slotname,opts={},&block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      message = opts['message'] || '#{meta}\'s #{slotname} should be present on #{on}'

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_presence_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on })
      end
    end 
    
    def validates_type_of(slotname,opts={},&block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      unless validation_type = opts['as']
        raise "validates_type_of requires :as => type"
      end
      message = opts['message'] || '#{meta}\'s #{slotname} should be of type #{validation_type}'
      
      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_type_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on, :type => validation_type })
      end
    end
    
    private 

    def initialize_validations
      before_save(:validates_presence_of) do |doc|
        presence_validations = doc.meta.slotnames.grep(/^validates_presence_of_/).map{|v| v.gsub(/^validates_presence_of_(.+)/,'\\1')}
        presence_validations.each do |slotname_to_validate|
          if validation=doc.meta["validates_presence_of_#{slotname_to_validate}"] 
            on = validation['on']
            if (on == 'create' && doc.new? && !doc.has_slot?(slotname_to_validate)) ||
               (on == 'update' && !doc.new? && !doc.has_slot?(slotname_to_validate)) ||
               (on == 'save' && !doc.has_slot?(slotname_to_validate))
              raise ValidationError.new(doc,validation['meta'],slotname_to_validate,on,validation['message'])
            end
          end
        end
      end
      before_save(:validates_type_of) do |doc|
        type_validations = doc.meta.slotnames.grep(/^validates_type_of_/).map{|v| v.gsub(/^validates_type_of_(.+)/,'\\1')}
        type_validations.each do |slotname_to_validate|
          if validation=doc.meta["validates_type_of_#{slotname_to_validate}"] 
            on = validation['on']
            klass = Kernel.const_get(validation[:type].to_s.camel_case)
            if (on == 'create' && doc.new? && doc.has_slot?(slotname_to_validate) && !doc[slotname_to_validate].is_a?(klass)) ||
               (on == 'update' && !doc.new? && doc.has_slot?(slotname_to_validate) && !doc[slotname_to_validate].is_a?(klass)) ||
               (on == 'save' && doc.has_slot?(slotname_to_validate) && !doc[slotname_to_validate].is_a?(klass))
              raise ValidationError.new(doc,validation['meta'],slotname_to_validate,on,validation['message'])
            end
         end
       end
      end


    end
    
  end  


end
