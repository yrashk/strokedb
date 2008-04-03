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
          unless condition_block?(condition)
            raise(
            ArgumentError,
            ":if/:unless clauses need to be either a symbol, string (to be eval'ed), proc/method, or " +
            "class implementing a static validation method"
            )
          end
        end
      end

      def evaluate_condition(condition, doc)
        case condition
        when Symbol then doc.send(condition)
        when String then eval(condition, doc.send(:binding))
        else
          condition.call(doc)
        end
      end

      def condition_block?(condition)
        condition.respond_to?("call") && (condition.arity == 1 || condition.arity == -1)
      end
    end
  end
end
