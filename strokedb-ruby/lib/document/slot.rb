module StrokeDB
  module ArrayWithLazyDocumentLoader
  end

  module HashWithLazyDocumentLoader
  end

  class DocumentReferenceValue < String
    attr_reader :str
    attr_accessor :doc
    def initialize(str,doc)
      @str, @doc = str, doc
      super(str)
    end
    def load
      case self
      when /@##{UUID_RE}.#{VERSION_RE}/
        if doc.head?
          @cached_value || @cached_value = doc.store.find($1) || "@##{$1}.#{$2}"
        else
          @cached_value || @cached_value = doc.store.find($1,$2) || "@##{$1}.#{$2}"
        end
      end
    end
    def inspect
      "#<DocRef #{self[0,5]}..>"
    end
    alias :to_raw :str
    
    def ==(v)
      case v
      when DocumentReferenceValue
        v.str == str
      when Document
        v == self
      else
        str == v
      end
    end


  end

  class Slot
    attr_reader :doc, :value

    def initialize(doc)
      @doc = doc
      @decoded = {}
    end

    def value=(v)
      @value = decode_value(encode_value(v,true))
    end

    def value
      if @value.is_a?(DocumentReferenceValue) 
        @value.doc = doc
        @value.load 
      else
        @value
      end
    end

    def to_raw
      raw_value.to_optimized_raw
    end



    def raw_value=(v)
      self.value = decode_value(v)
    end

    private

    def raw_value
      result = encode_value(@value)
      case result
      when Array
        result.map{|v| encode_value(v)}
      when Hash
        h = {}
        result.each_pair do |k,v|
          h[encode_value(k)] = encode_value(v)
        end
        h
      else
        result
      end
    end
    
    def encode_value(v,skip_documents=false)
      case v
      when Document
        skip_documents ? v : DocumentReferenceValue.new(v.__reference__,doc) 
      when Array
        LazyMappingArray.new(v).map_with do |element| 
          encode_value(element,skip_documents)
        end.unmap_with do |element|
          decode_value(element)
        end
      when Hash
        LazyMappingHash.new(v).map_with do |element| 
          encode_value(element,skip_documents)
        end.unmap_with do |element|
          decode_value(element)
        end
      when Symbol
        v.to_s
      else
        v
      end
    end

    def decode_value(v)
      case v
      when /@##{UUID_RE}.#{VERSION_RE}/
        DocumentReferenceValue.new(v,doc)
      when Array
        LazyMappingArray.new(v).map_with do |element| 
          decoded = decode_value(element)
          @decoded[decoded] ||= decoded.is_a?(DocumentReferenceValue) ? decoded.load : decoded
        end.unmap_with do |element|
          doc.send!(:update_version!,nil)
          encode_value(element)
        end
      when Hash
        LazyMappingHash.new(v).map_with do |element|
          decoded = decode_value(element)
          @decoded[decoded] ||= decoded.is_a?(DocumentReferenceValue) ? decoded.load : decoded
        end.unmap_with do |element|
          doc.send!(:update_version!,nil)
          encode_value(element)
        end
      when Symbol
        v.to_s
      else
        v
      end
    end

  end

end
