require 'base64'
module StrokeDB
  class Packet
    def initialize(documents)
      @documents = documents
    end

    # Each document is base64-encoded and separated with '#' character
    def to_base64_stream
      @documents.collect{|doc| Base64::encode64(doc.to_json(:transmittal => true)) }.join("#\n") + "#"
    end
  end

  class Base64StreamPacketReader
    def initialize(store,io)
      @store, @io = store, io
    end
    def read_packets
      until @io.eof?
        datum = ""
        until (line = @io.readline).starts_with?('#')
          datum << "#{line}\n"
        end
        packet = ActiveSupport::JSON.decode(Base64::decode64(datum))
        doc = Document.new(@store,packet.last)
        doc.instance_variable_set(:@uuid,packet.first)
        yield doc
      end
    end
  end
end