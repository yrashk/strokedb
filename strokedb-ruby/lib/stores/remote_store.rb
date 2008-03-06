module StrokeDB
  class Store
    def remote_server(host,port)
      RemoteStore::Server.new(self,host,port)
    end
  end
  module RemoteStore
    class Client

      attr_reader :host, :port

      def initialize(host,port)
        @host, @port = host, port
        DRb.start_service
        @server = DRbObject.new(nil, "druby://#{host}:#{port}")
      end

      def find(*args)
        safe_document_from_undumped(@server.find(*args))
      end
      
      def search(*args)
        @server.search(*args).map{|e| safe_document_from_undumped(e) }
      end
      
      def exists?(uuid)
        !!find(uuid,nil,:no_instantiation => true)
      end

      def head_version(uuid)
        raw_doc = find(uuid,nil,:no_instantiation => true)
        return raw_doc['__version__'] if raw_doc
        nil
      end
            
      def save!(*args)
        result = @server.save!(*args)
        if result.is_a?(Document)
          safe_document_from_undumped(result)
        end
        result
      end
      
      def each(options = {})
        @server.each(options) do |doc_without_store|
          safe_document_from_undumped(doc_without_store)
        end
      end
      
      def lamport_timestamp
        @server.lamport_timestamp
      end
      
      def next_lamport_timestamp
        @server.next_lamport_timestamp
      end
      
      def uuid
        @server.uuid
      end
      
      def document
        result = @server.document
        safe_document_from_undumped(result)
      end
      
      def empty?
        @server.empty?
      end

      def inspect
        @server.inspect
      end
      
      def index_store
        @server.index_store
      end
      
    private 
    
      def safe_document_from_undumped(doc_without_store)
        doc_without_store.instance_variable_set(:@store,self) if doc_without_store
        doc_without_store
      end
      
    end    

    class Server
      attr_reader :store, :host, :port, :thread
      def initialize(store,host,port)
        @store, @host, @port = store,host,port
      end
      
      def start
        DRb.start_service("druby://#{host}:#{port}", self)
        @thread = DRb.thread
      end

      def find(*args)
        @store.find(*args)
      end

      def search(*args)
        @store.search(*args)
      end
      
      def exists?(uuid)
        !!find(uuid,nil,:no_instantiation => true)
      end

      def head_version(uuid)
        raw_doc = find(uuid,nil,:no_instantiation => true)
        return raw_doc['__version__'] if raw_doc
        nil
      end
            
      def save!(document)
        document.instance_variable_set(:@store,self)
        @store.save!(document)
      end
      
      def each(options = {}, &block)
        @store.each(options, &block)
      end
      
      def lamport_timestamp
        @store.lamport_timestamp
      end
      
      def next_lamport_timestamp
        @store.next_lamport_timestamp
      end
      
      def uuid
        @store.uuid
      end
      
      def document
        @store.document
      end
      
      def empty?
        @store.empty?
      end

      def inspect
        @store.inspect
      end

      def index_store
        @store.index_store
      end

    end
  end
end
