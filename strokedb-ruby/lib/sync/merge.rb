# module StrokeDB
# 
#   class MergeStrategy ; end
#   
#   class SimplePatchMergeStrategy < MergeStrategy
#     def self.merge!(document,merge_with)
#       document_base = document.__versions__[document.previous_version.inspect] || merge_with.store.find(document.uuid,document.previous_version)
#       base_diff = merge_with.diff(document_base)
#       base_diff.patch!(document)
#       document[:__previous_version__] = merge_with.version # FIXME: I am not yet sure about it
#       document
#     end
#   end
#   
#   class MergeCondition < Exception
#     attr_reader :document, :merge_with
#     def initialize(document,merge_with)
#       @document, @merge_with = document, merge_with
#     end
#   end
#   
#   class MergingStore
#     attr_reader :store
#     def initialize(store)
#       @store = store
#     end
#     
#     def exists?(uuid)
#       @store.exists?(uuid)
#     end
#     
#     def last_version(uuid)
#       @store.last_version(uuid)
#     end
#     
#     def find(uuid,version=nil)
#       @store.find(uuid,version)
#     end
#     
#     def save!(document)
#       _last_version = find(document.uuid)
#       return store.save!(document) if document.versions.empty? || (_last_version[:__version__] && _last_version.version == document.previous_version)
#       return store.save!(document.meta[:__merge_strategy__].camelize.constantize.merge!(document,_last_version)) if document.meta && document.meta[:__merge_strategy__]
#       raise MergeCondition.new(document,_last_version)
#     end
#     
#     
#   end
#   
# end