require 'rubygems'
require 'diff/lcs'

module StrokeDB
  PATCH_REPLACE      = 'R'.freeze
  PATCH_STRING_PLUS  = '+'.freeze
  PATCH_STRING_MINUS = '-'.freeze
  
  class ::Object
    def stroke_diff(to)
      self == to ? nil : [PATCH_REPLACE, to]
    end
    def stroke_patch(patch)
      patch ? patch[1] : self
    end
  end
  class ::String
    def stroke_diff(to)
      return super(to) unless String === to
      return nil if self == to
      #puts "Diffing strings: #{self.inspect} vs. #{to.inspect}"
      # lcs_diff     -> [ [Change, Change, ...], ... ]
      lcs_diff = Diff::LCS.diff(self, to)
      # LCS.diff gives a huge list of of single-letter diffs.
      # Here we union sequentional updates in a single updates.
      # E.g. [['-', i, e], ... ['-', i + N, e]] => ['-', index, N]
      #p :lcs_diff => lcs_diff.map{|a|a.map{|b|b.to_a}} 
      patchset = lcs_diff.map do |changes| 
        parts = []
        last_part = changes.inject(nil) do |part, change|
          if part && part[0] == change.action && part[3] == change.position - 1
            part[3] += 1
            part[2] << change.element
            part
          else
            parts << part if part
            # emit
            [change.action, change.position, change.element, change.position]
          end
        end
        parts << last_part if last_part
        parts.empty? ? nil : parts
      end.compact.inject([]) do |patches, ps|
        ps.map do |p|
          patches << if p[0] == '+'
            [PATCH_STRING_PLUS,  p[1], p[2]]
          else
            [PATCH_STRING_MINUS, p[1], p[2].size]
          end
        end
        patches
      end
      #p patchset
      patchset.empty? ? nil : patchset
    end
    def stroke_patch(patch)
      return self unless patch
      #puts "#{self.inspect}.stroke_patch(#{patch.inspect}) "
      res = ""
      ai = bj = 0
      patch.each do |change|
        action, position, element = change
        case action
        when PATCH_STRING_MINUS
          d = position - ai
          if d > 0
            res << self[ai, d]
            ai += d
            bj += d
          end
          ai += element # element == length
          # while ai < position
          #   res << self[ai, 1]
          #   ai += 1
          #   bj += 1
          # end
          # ai += 1
        when PATCH_STRING_PLUS
          d = position - bj
          if d > 0
            res << self[ai, d]
            ai += d
            bj += d
          end
          bj += element.size
          # while bj < position
          #   res << self[ai, 1]
          #   ai += 1
          #   bj += 1
          # end
          # bj += 1
          res << element
        end
      end
      d = self.size - ai
      res << self[ai, d] if d > 0

      # while ai < src.size
      #   res << self[ai, 1]
      #   ai += 1
      #   bj += 1
      # end

      res
    end
  end
  
  class ::Array
    
  end
  
  
  class DeepDiff
    def diff(from, to)
      return yield_update(from, to) if from.class != to.class
      case from
      when String
        _f = from[0,2]
        _t = to[0,2]
        pfx = "@#"
        # both refs
        if _f == _t && _t == pfx
          yield_update(from, to)
        else
          # one of items is ref, another is not.
          if _f == pfx || _t == pfx
            yield_update(from, to)
          else
            diff_strings(from, to)
          end
        end
      when Array
        diff_arrays(from, to)
      when Hash
        diff_hashes(from, to)
      else
        yield_update(from, to)
      end
    end
  end
end



if __FILE__ == $0
  
  letters = %w(a b c)
  def gen_str(letters)
    str = ""
    len = rand(letters.size*2)
    len.times {
      str << letters[rand(letters.size)]
    }
    str
  end
  1000.times {
    from = gen_str(letters)
    to   = gen_str(letters)
    begin
      if from.stroke_patch(from.stroke_diff(to)) != to
        puts "Bug in the stroke_diff/patch!"
        p from
        p to
        p from.stroke_diff(to)
        p from.stroke_patch(from.stroke_diff(to))
        puts "-"*40
      end
    rescue => e
      puts "Exception in the stroke_diff/patch!"
      puts e
      puts e.backtrace.join("\n")
      p from
      p to
      puts "-"*40
    end
  }  
  p 
  
end

