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
        result = @server.find(*args)
        if result.is_a?(Document)
          result.instance_variable_set(:@store,self)
        end
        result
      end
      
      def save!(*args)
        result = @server.save!(*args)
        if result.is_a?(Document)
          result.instance_variable_set(:@store,self)
        end
        result
      end
      
      def document
        result = @server.document
        result.instance_variable_set(:@store,self)
        result
      end

      def method_missing(sym,*args,&block)
        @server.send(sym,*args,&block)
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

      def save!(document)
        document.instance_variable_set(:@store,self)
        @store.save!(document)
      end
      
      def find(*args)
        @store.find(*args)
      end
        
      def method_missing(sym,*args,&block)
        @store.send(sym,*args,&block)
      end
      

    end
  end
end
