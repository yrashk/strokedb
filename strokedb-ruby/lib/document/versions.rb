module StrokeDB
  class Document
    # Versions is a helper class that is used to navigate through versions. You should not
    # instantiate it directly, but using Document#__versions__ method
    # 
    class Versions
      attr_reader :document
      def initialize(document)  #:nodoc:
        @document = document
        @cache = {}
      end


      #
      # Get document by version.
      #
      # Returns Document instance
      # Returns <tt>nil</tt> if there is no document with given version
      #
      def [](version)
        @cache[version] ||= @document.store.find(document.uuid,version)
      end

      #
      # Get current version of document
      #
      def current
        document.new? ? document.clone.extend(VersionedDocument) : self[document.__version__]
      end

      #
      # Get head version of document
      #
      def head
        document.new? ? document.clone.extend(VersionedDocument) : document.store.find(document.uuid)
      end

      #
      # Get first version of document
      #
      def first
        document.new? ? document.clone.extend(VersionedDocument) : self[all_preceding_versions.last]
      end



      #
      # Get document with previous version
      #
      # Returns Document instance
      # Returns <tt>nil</tt> if there is no previous version
      #
      def previous
        self[document.__previous_version__]
      end

      #
      # Find all document versions, treating current one as a head
      #
      # Returns an Array of version numbers
      #
      def all_versions
        [document.__version__,*all_preceding_versions]
      end

      #
      # Get all versions of document including currrent one
      #
      # Returns an Array of Documents
      #
      def all
        all_versions.map{|v| self[v]}
      end


      #
      # Find all _previous_ document versions, treating current one as a head
      #
      # Returns an Array of version numbers
      #
      def all_preceding_versions
        if previous_version = document.__previous_version__
          [previous_version, *self[previous_version].__versions__.all_preceding_versions]
        else
          []
        end
      end

      #
      # Find all previous versions of document
      #
      # Returns an Array of Documents
      #
      def all_preceding
        all_preceding_versions.map{|v| self[v]}
      end

      #
      # Returns <tt>true</tt> if document has no previous versions
      #
      def empty?
        document.__previous_version__.nil?
      end
    end
  end
end