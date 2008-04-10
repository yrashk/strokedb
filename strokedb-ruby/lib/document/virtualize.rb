module StrokeDB
  module Virtualizations
    #
    # Makes a virtual slot. Virtual slot is by all means a regular slot with
    # one exception: it doesn't get serialized on save. Nevertheless its value
    # is preserved while the document is in memory. You can also set :restore
    # option to false (it is true by default), in such case the slot will be
    # removed before save and not restored. It may be useful for ad hoc slots.
    #
    # Virtual slots get validated as usual.
    #
    #   User = Meta.new do
    #     virtualizes :password, :restore => false
    #     validates_presence_of :crypted_password
    #   end
    #
    # Regular password is not meant to get serialized in this example, only the
    # crypted one.
    #
    def virtualizes(slotnames, opts = {})
      opts = opts.stringify_keys

      slotnames = [slotnames] unless slotnames.is_a?(Array)
      slotnames.each {|slotname| register_virtual(slotname, opts)}
    end

    private

    # FIXME: willn't usage of instance variables below make a mess in a threaded mode?
    def initialize_virtualizations
      after_validation do |doc|
        @saved_virtual_slots = {}
        @version = doc.version
        @previous_version = doc.previous_version

        grep_slots(doc, "virtualizes_") do |virtual_slot, meta_slotname|
          if doc.meta[meta_slotname][:restore]
            @saved_virtual_slots[virtual_slot] = doc[virtual_slot]
          end

          doc.remove_slot!(virtual_slot)
        end
      end

      after_save do |doc|
        @saved_virtual_slots.each do |slot, value|
          doc[slot] = value
        end
        unless @saved_virtual_slots.empty?
          doc['version'] = @version

          if @previous_version
            doc['previous_version'] = @previous_version 
          else
            doc.remove_slot!('previous_version')
          end
        end

        @version = nil
        @previous_version = nil
        @saved_virtual_slots = {}
      end
    end

    def register_virtual(slotname, opts)
      slotname = slotname.to_s

      restore = opts['restore'].nil? ? true : !!opts['restore']

      options_hash = { 
        :slotname => slotname, 
        :restore => restore
      }

      virtualize_slot = "virtualizes_#{slotname}"

      @meta_initialization_procs << Proc.new do
        @args.last.reverse_merge!(virtualize_slot => { :meta => name }.merge(options_hash))
      end
    end
  end
end
