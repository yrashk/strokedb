module StrokeDB
  class Replica < Document
    def replicate!(document)
      self[document.uuid] = document.all_versions - (self[document.uuid]||[]) - 
                            previous_versions.collect{|r| store.find(uuid,r)[document.uuid]}.flatten.uniq
      save!
    end

    def update_replications!
      @slots.each_pair do |k,v|
        if k.match(UUID_RE)
          self[k] = store.find($1).all_versions - self[k]
        end
      end
      save!
    end
    
    def to_packet
      docs = []
      @slots.each_pair do |k,v|
        if k.match(UUID_RE)
          self[k].each {|version| docs << store.find($1,version) }
        end
      end
      docs << self
      Packet.new(docs)
    end
  end
end
