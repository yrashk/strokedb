module StrokeDB
  module Virtualizations
    def virtualizes(slotnames, opts = {})
      opts = opts.stringify_keys

      check_condition(opts['if']) if opts['if']
      check_condition(opts['unless']) if opts['unless']
      
      slotnames = [slotnames] unless slotnames.is_a?(Array)
      slotnames.each {|slotname| register_virtual(slotname, opts)}
    end

    private

    def initialize_virtualizations
      after_validation do |doc|
        @saved_virtual_slots = {}

        grep_slots(doc, "virtualizes_") do |virtual_slot, slotname|
          virtual_slot = virtual_slot.to_sym
          @saved_virtual_slots[virtual_slot] = doc[virtual_slot]
          doc.remove_slot!(virtual_slot)
        end
      end

      after_save do |doc|
        @saved_virtual_slots.each do |slot, value|
          doc[slot] = value
        end

        @saved_virtual_slots = {}
      end
    end
    
    def register_virtual(slotname, opts)
      slotname = slotname.to_s

      options_hash = { 
        :slotname => slotname, 
        :if => opts['if'],  
        :unless => opts['unless']
      }

      virtualize_slot = "virtualizes_#{slotname}"

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!(virtualize_slot => { :meta => name }.merge(options_hash))
      end
    end
  end
end
