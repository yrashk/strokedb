require 'ostruct'

# TODO (taken from ActiveRecord):
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
    def validates_presence_of(slotname, opts={}, &block)
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
    def validates_type_of(slotname, opts={}, &block)
      register_validation("type_of", slotname, opts, '#{meta}\'s #{slotname} should be of type #{validation_type}') do |opts|
        unless type = opts['as']
          raise ArgumentError, "validates_type_of requires :as => type"
        end

        { :validation_type => type.to_s.capitalize }
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
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_uniqueness_of(slotname, opts={}, &block)
      register_validation("uniqueness_of", slotname, opts, 'A document with a #{slotname} of #{slotvalue} already exists')
    end
    
    # Validates that the specified slot value is numeric
    #
    #   Item = Meta.new do
    #     validates_numericality_of :price
    #   end
    #
    # Configuration options:
    # * <tt>only_integer</tt> - Specify integer
    # * <tt>message</tt> - A custom error message (default is: "Value of ... must be numeric | integer")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_numericality_of(slotname, opts={}, &block)
  
      validation_type = opts[:only_integer] ? 'integer' : 'numeric'

      register_validation("numericality_of", slotname, opts, "Value of #{slotname} must be #{validation_type}") do |opts|
        { :validation_type => validation_type.capitalize, :only_integer => opts['only_integer'] }
      end          

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

    def initialize_validations
      install_validations_for(:validates_presence_of) do |doc, validation, slotname|
        doc.has_slot? slotname
      end
      
      install_validations_for(:validates_type_of) do |doc, validation, slotname|
        !doc.has_slot?(slotname) || doc[slotname].is_a?(Kernel.const_get(validation[:validation_type]))
      end

      install_validations_for(:validates_uniqueness_of) do |doc, validation, slotname|
        meta = Kernel.const_get(doc.meta.name)

        !doc.has_slot?(slotname) || 
        !(found = meta.find(slotname.to_sym => doc[slotname])) || 
        (found.size == 0) || 
        (found.first == doc) ||
        (found.first.version == doc.previous_version)
      end

      install_validations_for(:validates_numericality_of) do |doc, validation, slotname|
        value = doc[slotname].to_s
        regex = validation[:only_integer] ? /\A[+-]?\d+\Z/ : /^\d*\.{0,1}\d+$/
        !doc.has_slot?(slotname) ||
        !(value =~ regex).nil?
      end
    end

    def install_validations_for(sym, &block)
      on_validation(sym) do |doc|
        grep_validations(doc, sym.to_s + "_") do |slotname_to_validate, meta_slotname|
          if validation = doc.meta[meta_slotname] 
            on = validation['on']

            should_call = ((on == 'create' && doc.new?) || (on == 'update' && !doc.new?) || on == 'save') &&
              (!validation[:if]     || evaluate_condition(validation[:if], doc)) &&
              (!validation[:unless] || !evaluate_condition(validation[:unless], doc))
	  
            if should_call && !block.call(doc, validation, slotname_to_validate)
              os = OpenStruct.new(validation)
              os.document = doc
              os.slotvalue = doc[slotname_to_validate]

              doc.errors.add(slotname_to_validate, os.instance_eval("\"#{validation['message']}\""))
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
