module StrokeDB
  module Meta
    module Util
      def grep_slots(doc, prefix)
        doc.meta.slotnames.each do |slotname|
          if slotname[0..(prefix.length - 1)] == prefix
            yield slotname[prefix.length..-1], slotname
          end
        end
      end

      def check_condition(condition)
        case condition
        when Symbol, String then return
        else
          raise ArgumentError, ":if/:unless clauses need to be either a symbol or string (slotname or method name)"
        end
      end

      def evaluate_condition(condition, doc)
        case condition
        when String then doc.send(condition)
        end
      end
    end
  end
end
