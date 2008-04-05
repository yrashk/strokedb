require 'ostruct'

# TODO (taken from ActiveRecord):
#   validates_length_of
#   validates_associated
#
module StrokeDB
  module Validations
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
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_presence_of(slotname, opts={})
      register_validation("presence_of", slotname, opts, '#{meta}\'s #{slotname} should be present on #{on}')
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
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # 
    # === Warning
    # When the slot doesn't exist, validation gets skipped.
    def validates_type_of(slotname, opts={})
      register_validation("type_of", slotname, opts, '#{meta}\'s #{slotname} should be of type #{validation_type}') do |opts|
        unless type = opts['as']
          raise ArgumentError, "validates_type_of requires :as => type"
        end

        { 
          :validation_type => type.to_s.capitalize,
          :allow_nil => !!opts['allow_nil'] 
        }
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
    # * <tt>case_sensitive</tt> - Looks for an exact match.  Ignored by non-text columns (true by default).
    # * <tt>allow_nil</tt> - If set to true, skips this validation if the attribute is null (default is: false)
    # * <tt>allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is: false)
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_uniqueness_of(slotname, opts={})
      register_validation("uniqueness_of", slotname, opts, 'A document with a #{slotname} of #{slotvalue} already exists') do |opts|
        { :allow_nil => !!opts['allow_nil'], :allow_blank => !!opts['allow_blank'] }
      end
    end
    
    # Validates whether the value of the specified slot is available in a particular enumerable object.
    #
    #   Person = Meta.new do
    #     validates_inclusion_of :gender, :in => %w( m f ), :message => "woah! what are you then!??!!"
    #     validates_inclusion_of :age, :in => 0..99
    #     validates_inclusion_of :format, :in => %w( jpg gif png ), :message => 'extension #{slotvalue} is not included in the list'
    #   end
    #
    # Configuration options:
    # * <tt>in</tt> - An enumerable object of available items
    # * <tt>message</tt> - Specifies a customer error message (default is: "is
    #   not included in the list")
    # * <tt>allow_nil</tt> - If set to true, skips this validation if the slot is null (default is: false)
    # * <tt>allow_blank</tt> - If set to true, skips this validation if the slot is blank (default is: false)
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should occur
    #   (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }). The method, proc or string
    #   should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should not occur
    #   (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }). The method, proc or string
    #   should return or evaluate to a true or false value.
    def validates_inclusion_of(slotname, opts={})
      if opts[:in]
        raise ArgumentError, "object must respond to the method include?" unless opts[:in].respond_to? :include?
        register_validation("inclusion_of", slotname, opts, "Value of #{slotname} is not included in the list") do |opts|
          { 
            :in => opts['in'],
            :allow_nil => !!opts['allow_nil'],
            :allow_blank => !!opts['allow_blank'] 
          }
        end
      else
        raise ArgumentError, "validates_inclusion_of requires :in => Enumerable"
      end
    end 
    
    # Validates that the value of the specified slot is not in a particular enumerable object.
    #
    #   class Person < ActiveRecord::Base
    #     validates_exclusion_of :username, :in => %w( admin superuser ), :message => "You don't belong here"
    #     validates_exclusion_of :age, :in => 30..60, :message => "This site is only for under 30 and over 60"
    #     validates_exclusion_of :format, :in => %w( mov avi ), :message => 'extension #{slotvalue} is not allowed'
    #   end
    #
    # Configuration options:
    # * <tt>in</tt> - An enumerable object of items that the value shouldn't be part of
    # * <tt>message</tt> - Specifies a customer error message (default is: "is reserved")
    # * <tt>allow_nil</tt> - If set to true, skips this validation if the attribute is null (default is: false)
    # * <tt>allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is: false)
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_exclusion_of(slotname, opts={})
      if opts[:in]
        raise ArgumentError, "object must respond to the method include?" unless opts[:in].respond_to? :include?
        register_validation("exclusion_of", slotname, opts, "Value of #{slotname} is reserved") do |opts|
          { 
            :in => opts['in'],
            :allow_nil => !!opts['allow_nil'],
            :allow_blank => !!opts['allow_blank'] 
          }
        end
      else
        raise ArgumentError, "validates_exclusion_of requires :in => Enumerable"
      end
    end 
      
    # Validates whether the value of the specified attribute is numeric by trying to convert it to
    # a float with Kernel.Float (if <tt>only_integer</tt> is false) or applying it to the regular expression
    # <tt>/\A[\+\-]?\d+\Z/</tt> (if <tt>only_integer</tt> is set to true).
    #
    #   Item = Meta.new do
    #     validates_numericality_of :price
    #   end
    #
    # * <tt>message</tt> - A custom error message (default is: "is not a number")
    # * <tt>on</tt> Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>only_integer</tt> Specifies whether the value has to be an integer, e.g. an integral value (default is false)
    # * <tt>allow_nil</tt> Skip validation if attribute is nil (default is
    #   false). Notice that for fixnum and float columns empty strings are converted to nil
    # * <tt>greater_than</tt> Specifies the value must be greater than the supplied value
    # * <tt>greater_than_or_equal_to</tt> Specifies the value must be greater than or equal the supplied value
    # * <tt>equal_to</tt> Specifies the value must be equal to the supplied value
    # * <tt>less_than</tt> Specifies the value must be less than the supplied value
    # * <tt>less_than_or_equal_to</tt> Specifies the value must be less than or equal the supplied value
    # * <tt>odd</tt> Specifies the value must be an odd number
    # * <tt>even</tt> Specifies the value must be an even number
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    NUMERICALITY_CHECKS = { 'greater_than' => :>, 'greater_than_or_equal_to' => :>=,
                                'equal_to' => :==, 'less_than' => :<, 'less_than_or_equal_to' => :<=,
                                'odd' => :odd?, 'even' => :even? }.freeze

    def validates_numericality_of(slotname, opts={})
      register_validation("numericality_of", slotname, opts, nil) do |opts|
        numeric_checks = opts.reject { |key, val| !NUMERICALITY_CHECKS.include? key }

        %w(odd even).each do |o|
          raise ArgumentError, ":#{o} must be set to true if set at all" if opts.include?(o) && opts[o] != true
        end

        (numeric_checks.keys - %w(odd even)).each do |option|
          raise ArgumentError, "#{option} must be a number" unless opts[option].is_a? Numeric
        end
 
        {
          :only_integer => opts['only_integer'],
          :numeric_checks => numeric_checks,
          :allow_nil => !!opts['allow_nil']
        }
      end          
    end
    
    # Validates whether the value of the specified attribute is of the correct
    # form by matching it against the regular expression provided.
    #
    #   Person = Meta.new do
    #     validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create
    #   end
    #
    # Note: use \A and \Z to match the start and end of the string, ^ and $ match the start/end of a line.
    #
    # A regular expression must be provided or else an exception will be
    # raised.
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "is invalid")
    # * <tt>with</tt> - The regular expression used to validate the format with (note: must be supplied!)
    # * <tt>on</tt> Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_format_of(slotname, opts={})
      register_validation("format_of", slotname, opts, 'Value of #{slotname} should match #{slotvalue}') do |opts|
        unless regexp = opts['with'].is_a?(Regexp)
          raise ArgumentError, "validates_format_of requires :with => regexp"
        end
        { :with => opts['with'] }
      end
    end
       
    # Encapsulates the pattern of wanting to validate a password or email
    # address field with a confirmation. Example:
    #
    #   Model:
    #     Person = Meta.new
    #       validates_confirmation_of :password
    #       validates_confirmation_of :email_address, :message => "should match confirmation"
    #     end
    #
    #   View:
    #     <%= password_field "person", "password" %>
    #     <%= password_field "person", "password_confirmation" %>
    #
    # The added +password_confirmation+ slot is virtual; it exists only as
    # an in-memory slot for validating the password. To achieve this, the
    # validation adds accessors to the model for the confirmation slot.
    # NOTE: This check is performed only if +password_confirmation+ is not nil,
    # and by default only on save. To require confirmation, make sure to add a
    # presence check for the confirmation attribute:
    #
    #   validates_presence_of :password_confirmation, :if => :password_changed?
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "doesn't match confirmation")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.      
    def validates_confirmation_of(slotname, opts = {})
      register_validation("confirmation_of", slotname, opts, '#{meta}\'s #{slotname} doesn\'t match confirmation')

      virtualizes(slotname.to_s + "_confirmation")
    end
    
    # Encapsulates the pattern of wanting to validate the acceptance of a terms
    # of service check box (or similar agreement). Example:
    #
    #   Person = Meta.new
    #     validates_acceptance_of :terms_of_service
    #     validates_acceptance_of :eula, :message => "must be abided"
    #   end
    #
    # The terms_of_service and eula slots are virtualized. This check is
    # performed only if terms_of_service is not nil and by default on save.
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "must be accepted")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>allow_nil</tt> - Skip validation if attribute is nil. (default is true)
    # * <tt>accept</tt> - Specifies value that is considered accepted.  The default value is a string "1", which
    #   makes it easy to relate to an HTML checkbox. This should be set to 'true' if you are validating a database
    #   column, since the attribute is typecast from "1" to <tt>true</tt> before validation.
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.      
    def validates_acceptance_of(slotname, opts = {})
      register_validation("acceptance_of", slotname, opts, '#{slotname} must be accepted') do |opts|
        allow_nil = opts['allow_nil'].nil? ? true : !!opts['allow_nil']
        accept = opts['accept'] || "1"

        { :allow_nil => allow_nil, :accept => accept }
      end

      virtualizes(slotname.to_s)
    end

    # this module gets mixed into Document
    module InstanceMethods
      class Errors
        include Enumerable

        def initialize(base)
          @base, @errors = base, {}
        end

        def add(slot, msg)
          slot = slot.to_s
          @errors[slot] = [] if @errors[slot].nil?
          @errors[slot] << msg
        end

        def invalid?(slot)
          !@errors[slot.to_s].nil?
        end

        def on(slot)
          errors = @errors[slot.to_s]
          return nil if errors.nil?
          errors.size == 1 ? errors.first : errors
        end

        alias :[] :on

        # Returns true if no errors have been added.
        def empty?
          @errors.empty?
        end

        # Removes all errors that have been added.
        def clear
          @errors = {}
        end
        
        # Returns all the error messages in an array.
        def messages
          @errors.values.inject([]) { |error_messages, slot| error_messages + slot }
        end

        # Returns the total number of errors added. Two errors added to the
        # same slot will be counted as such.
        def size
          @errors.values.inject(0) { |error_count, slot| error_count + slot.size }
        end

        alias_method :count, :size
        alias_method :length, :size
      end

      # Runs validations and returns true if no errors were added otherwise false.
      def valid?
        errors.clear
        
        execute_callbacks :on_validation

        errors.empty?
      end

      # Returns the Errors object that holds all information about attribute
      # error messages.
      def errors
        @errors ||= Errors.new(self)
      end
    end
    
    private 
    
    def register_validation(validation_name, slotname, opts, message)
      opts = opts.stringify_keys
      slotname = slotname.to_s
      on = (opts['on'] || 'save').to_s.downcase
      message = opts['message'] || message
    
      check_condition(opts['if']) if opts['if']
      check_condition(opts['unless']) if opts['unless']

      options_hash = { 
        :slotname => slotname, 
        :message => message, 
        :on => on,
        :if => opts['if'],  
        :unless => opts['unless']
      }

      options_hash.merge!(yield(opts)) if block_given?

      validation_slot = "validates_#{validation_name}_#{slotname}"

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!(validation_slot => { :meta => name }.merge(options_hash))
      end
    end

    NUMERICALITY_ERRORS = { 
      'greater_than' => '#{slotname} must be greater than %d', 
      'greater_than_or_equal_to' => '#{slotname} must be greater than or equal to %d',
      'equal_to' => '#{slotname} must be equal to %d', 
      'less_than' => '#{slotname} must be less than %d',
      'less_than_or_equal_to' => '#{slotname} must be less than or equal to %d',
      'odd' => '#{slotname} must be odd',
      'even' => '#{slotname} must be even'
    }.freeze unless defined? NUMERICALITY_ERRORS

    def initialize_validations
      install_validations_for(:validates_presence_of) do |doc, validation, slotname|
        doc.has_slot? slotname
      end
      
      install_validations_for(:validates_type_of) do |doc, validation, slotname|
        doc[slotname].is_a? Kernel.const_get(validation[:validation_type])
      end
      
      install_validations_for(:validates_inclusion_of) do |doc, validation, slotname|
        validation[:in].include? doc[slotname]
      end
      
      install_validations_for(:validates_exclusion_of) do |doc, validation, slotname|
        !validation[:in].include?(doc[slotname])
      end
     
      install_validations_for(:validates_format_of) do |doc, validation, slotname|
        !(doc[slotname] !~ validation[:with])
      end
      
      install_validations_for(:validates_uniqueness_of) do |doc, validation, slotname|
        meta = Kernel.const_get(doc.meta.name)

        !(found = meta.find(slotname.to_sym => doc[slotname])) || 
        (found.size == 0) || 
        (found.first == doc) ||
        (found.first.version == doc.previous_version)
      end
      
      # using lambda here enables us to use return
      numericality = lambda do |doc, validation, slotname|
        value = doc[slotname]

        if validation[:only_integer]
          return (validation[:message] || "#{slotname} must be integer") unless value.to_s =~ /\A[+-]?\d+\Z/
          value = value.to_i
        else
          value = Kernel.Float(value) rescue false
          return (validation[:message] || "#{slotname} is not a number") unless value
        end

        errors = []

        validation[:numeric_checks].each do |option, optvalue|
          testresult = if %w(odd even).include? option
            value.to_i.send(NUMERICALITY_CHECKS[option])
          else
            value.send(NUMERICALITY_CHECKS[option], optvalue)
          end

          unless testresult
            errors << ((validation[:message] || NUMERICALITY_ERRORS[option]) % optvalue)
          end
        end

        errors.empty? ? true : errors
      end

      install_validations_for(:validates_numericality_of, &numericality) 
      install_validations_for(:validates_confirmation_of) do |doc, validation, slotname|
        confirm_slotname = slotname + "_confirmation"
        !doc.has_slot?(confirm_slotname) || doc[slotname] == doc[confirm_slotname]
      end
      
      install_validations_for(:validates_acceptance_of) do |doc, validation, slotname|
        doc[slotname] == validation[:accept] 
      end
    end

    def install_validations_for(sym, &block)
      on_validation(sym) do |doc|
        grep_slots(doc, sym.to_s + "_") do |slotname_to_validate, meta_slotname|
          next unless validation = doc.meta[meta_slotname] 
          
          on = validation['on']

          next unless (on == 'create' && doc.new?) || (on == 'update' && !doc.new?) || on == 'save'
          next if validation[:if]     && !evaluate_condition(validation[:if], doc)
          next if validation[:unless] &&  evaluate_condition(validation[:unless], doc)

          value = doc[slotname_to_validate]
          
          next if validation[:allow_nil] && value.nil?
          next if validation[:allow_blank] && value.blank?

          case validation_result = block.call(doc, validation, slotname_to_validate)
            when true then next
            when false
              add_error(doc, validation, slotname_to_validate, validation[:message])
            when String
              add_error(doc, validation, slotname_to_validate, validation_result)
            when Array
              validation_result.each { |message| add_error(doc, validation, slotname_to_validate, message) }
          end
        end
      end
    end

    def add_error(doc, validation, slotname, message)
      os = OpenStruct.new(validation)
      os.document = doc
      os.slotvalue = doc[slotname]

      doc.errors.add(slotname, os.instance_eval("\"#{message}\""))
    end
  end  
end
