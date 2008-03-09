module StrokeDB
  class NonMatchingDocumentCondition < Exception
    attr_reader :uuid
    def initialize(uuid)
      @uuid = uuid
    end
  end
  class ConflictCondition < Exception
    attr_reader :uuid, :rev1, :rev2
    def initialize(uuid, rev1, rev2)
      @uuid, @rev1, @rev2 = uuid, rev1, rev2
    end
  end
  
  class Store
    def sync!(docs,timestamp=nil)
      existing_chain = {}
      docs.group_by {|doc| doc.uuid}.each_pair do |uuid, versions|
        doc = find(uuid)
        existing_chain[uuid] = doc.__versions__.all_versions if doc 
      end
      case timestamp
      when Numeric
        @lamport_timestamp = LTS.new(timestamp,@lamport_timestamp.uuid) 
      when LamportTimestamp
        @lamport_timestamp = LTS.new(timestamp.counter,@lamport_timestamp.uuid)
      else
      end
      docs.each {|doc| save!(doc) unless exists?(doc.uuid,doc.__version__)}
      docs.group_by {|doc| doc.uuid}.each_pair do |uuid, versions|
        incoming_chain = find(uuid,versions.last.__version__).__versions__.all_versions
        if existing_chain[uuid].nil? or existing_chain[uuid].empty? # It is a new document
          save_as_head!(find(uuid,versions.last.__version__))
        else
          begin
            sync = sync_chains(incoming_chain.reverse,existing_chain[uuid].reverse)
          rescue NonMatchingChains
            raise NonMatchingDocumentCondition.new(uuid) # that will definitely leave garbage in the store (FIXME?)
          end
          resolution = sync.is_a?(Array) ? sync.first : sync
          case resolution
          when :up_to_date
            # nothing to do
          when :merge
            raise ConflictCondition.new(uuid, sync[1], sync[2])
          when :fast_forward
            save_as_head!(find(uuid,sync[1].last))
          else
            raise "Invalid sync resolution #{resolution}"
          end
        end
      end
    end
    private
    
    include ChainSync
    
  end
end
