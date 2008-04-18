require 'drb'
require 'drb/acl'
require 'drb/unix'

module StrokeDB
  class Store
    def remote_server(addr, protocol=:drb)
      case protocol
      when :drb
        RemoteStore::DRb::Server.new(self,"#{addr}")
      else
        raise "No #{protocol} protocol"
      end
    end
  end
  module RemoteStore
    module DRb
      class Client

        attr_reader :addr

        def initialize(addr)
          @addr = addr
          ::DRb.start_service
          @server = ::DRbObject.new(nil, addr)
        end

        def find(*args)
          safe_document_from_undumped(@server.find(*args))
        end

        def search(*args)
          @server.search(*args).map{ |e| safe_document_from_undumped(e) }
        end

        def include?(uuid, version=nil)
          @server.include?(uuid, version)
        end
        alias_method :contains?, :include?

        def head_version(uuid)
          raw_doc = find(uuid,nil, :no_instantiation => true)
          return raw_doc['version'] if raw_doc
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

        def timestamp
          @server.timestamp
        end

        def next_timestamp
          @server.next_timestamp
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
          doc_without_store.instance_variable_set(:@store, self) if doc_without_store
          doc_without_store
        end

      end    

      class Server
        attr_reader :store, :addr, :thread
        def initialize(store, addr)
          @store, @addr = store, addr
          @mutex = Mutex.new
        end

        def start
          ::DRb.start_service(addr, self)
          @thread = ::DRb.thread
        end

        def find(*args)
          @mutex.synchronize { @store.find(*args) }
        end

        def search(*args)
          @mutex.synchronize { @store.search(*args) }
        end

        def include?(*args)
          !!@mutex.synchronize { @store.include?(*args) }
        end
        alias_method :contains?, :include?

        def head_version(uuid)
          raw_doc = @mutex.synchronize { find(uuid, nil, :no_instantiation => true) }
          return raw_doc['version'] if raw_doc
          nil
        end

        def save!(document)
          document.instance_variable_set(:@store, @store)
          @mutex.synchronize { @store.save!(document) }
        end

        def each(options = {}, &block)
          @mutex.synchronize { @store.each(options, &block) }
        end

        def timestamp
          @mutex.synchronize { @store.timestamp }
        end

        def next_timestamp
          @mutex.synchronize { @store.next_timestamp }
        end

        def uuid
          @store.uuid
        end

        def document
          @mutex.synchronize { @store.document }
        end

        def empty?
          @mutex.synchronize { @store.empty? }
        end
        
        def autosync!
          @mutex.synchronize { @store.autosync! }
        end
        
        def stop_autosync!
          @mutex.synchronize { @store.stop_autosync! }
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
end
