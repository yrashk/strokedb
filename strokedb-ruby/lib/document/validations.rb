# TODO (taken from ActiveRecord):
#   validate (with a method)
#   validates_each
#   validates_confirmation_of
#   validates_acceptance_of
#   validates_length_of
#   validates_uniqueness_of
#   validates_format_of
#   validates_inclusion_of
#   validates_exclusion_of
#   validates_associated
#   validates_numericality_of
#
#   :if and :unless options for all
#
# Consider also using validatable gem (DataMapper is now switching to it)
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
    
    # Validates that the specified slot exists in the document. Happens by default on save. Example:
    #
    #   Person = Meta.new do
    #     validates_presence_of :first_name
    #   end
    #
    # The first_name slot must be in the document.
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "should be present on ...")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>if</tt> - (UNSUPPORTED) Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - (UNSUPPORTED) Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_presence_of(slotname, opts={}, &block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      message = opts['message'] || '#{meta}\'s #{slotname} should be present on #{on}'

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_presence_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on })
      end
    end 
    
    # Validates that the specified slot value has a specific type. Happens by default on save. Example:
    #
    #   Person = Meta.new do
    #     validates_type_of :first_name, :as => :string
    #   end
    #
    # The first_name value for each Person must be unique.
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "document with value already exists")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>if</tt> - (UNSUPPORTED) Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - (UNSUPPORTED) Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # 
    # === Warning
    # When the slot doesn't exist, validation gets skipped.
    def validates_type_of(slotname, opts={}, &block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      unless validation_type = opts['as']
        raise ArgumentError, "validates_type_of requires :as => type"
      end
      message = opts['message'] || '#{meta}\'s #{slotname} should be of type #{validation_type}'
      
      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_type_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on, :type => validation_type })
      end
    end

    # Validates that the specified slot value is unique in the store
    #
    #   Person = Meta.new do
    #     validates_uniqueness_of :first_name
    #   end
    #
    # The first_name slot must be in the document.
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "A document with a ... of ... already exists")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>if</tt> - (UNSUPPORTED) Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - (UNSUPPORTED) Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_uniqueness_of(slotname, opts={}, &block)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      message = opts['message'] || 'A document with a #{slotname} of #{value} already exists'
      
      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!("validates_uniqueness_of_#{slotname}" => { :meta => name, :slotname => slotname, :message => message, :on => on })
      end
    end

    private 

    def initialize_validations
      install_validations_for(:validates_presence_of) do |doc, validation, slotname|
        doc.has_slot? slotname
      end
      
      install_validations_for(:validates_type_of) do |doc, validation, slotname|
        !doc.has_slot?(slotname) || doc[slotname].is_a?(Kernel.const_get(validation[:type].to_s.capitalize))
      end

      install_validations_for(:validates_uniqueness_of) do |doc, validation, slotname|
        meta = Kernel.const_get(doc.meta.name)
        !doc.has_slot?(slotname) || !meta.find(slotname.to_sym => doc[slotname]) || !(meta.find(slotname.to_sym => doc[slotname]).size > 0)
      end
    end

    def install_validations_for(sym, &block)
      before_save(sym) do |doc|
        grep_validations(doc, sym.to_s + "_") do |slotname_to_validate, meta_slotname|
          if validation = doc.meta[meta_slotname] 
            on = validation['on']
            
            if (on == 'create' && doc.new? && !block.call(doc, validation, slotname_to_validate)) ||
               (on == 'update' && !doc.new? && !block.call(doc, validation, slotname_to_validate)) ||
               (on == 'save' && !block.call(doc, validation, slotname_to_validate))
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
