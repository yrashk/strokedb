require 'rubygems'
require 'diff/lcs'

module StrokeDB
  PATCH_REPLACE = 'R'.freeze
  PATCH_PLUS    = '+'.freeze
  PATCH_MINUS   = '-'.freeze
  PATCH_DIFF    = '!'.freeze
  
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
            [PATCH_PLUS,  p[1], p[2]]
          else
            [PATCH_MINUS, p[1], p[2].size]
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
        when PATCH_MINUS
          d = position - ai
          if d > 0
            res << self[ai, d]
            ai += d
            bj += d
          end
          ai += element # element == length
        when PATCH_PLUS
          d = position - bj
          if d > 0
            res << self[ai, d]
            ai += d
            bj += d
          end
          bj += element.size
          res << element
        end
      end
      d = self.size - ai
      res << self[ai, d] if d > 0
      res
    end
  end
  
  class ::Array
    SDATPTAGS = {
      '-' => PATCH_MINUS,
      '+' => PATCH_PLUS,
      '!' => PATCH_DIFF
    }.freeze
    def stroke_diff(to)
      return super(to) unless Array === to
      return nil if self == to
      
      # sdiff:  +   -   !   = 
      lcs_sdiff = Diff::LCS.sdiff(self, to)
      patchset = []
      last_part = lcs_sdiff.inject(nil) do |part, change|
        a = SDATPTAGS[change.action]
        if part && part[0] == a && a != PATCH_DIFF
          if a == '+'
            part[2] << change.new_element
          else
            part[2] += 1
          end
          part
        else
          patchset << part if part
          # emit
          if a == '!' 
            [a, change.old_position, change.new_position, 
                change.old_element.stroke_diff(change.new_element)]
          elsif a == '-'
            [a, change.old_position, 1]
          elsif a == '+'
            [a, change.new_position, [change.new_element]]
          else 
            nil
          end
        end
      end
      patchset << last_part if last_part
      patchset.empty? ? nil : patchset
    end
    
    def stroke_patch(patch)
      return self unless patch
      #puts "#{self.inspect}.stroke_patch(#{patch.inspect}) "
      res = []
      ai = bj = 0
      patch.each do |change|
        action, position, element = change
        case action
        when PATCH_MINUS
          d = position - ai
          if d > 0
            res += self[ai, d]
            ai += d
            bj += d
          end
          ai += element # element == length
        when PATCH_PLUS
          d = position - bj
          if d > 0
            res += self[ai, d]
            ai += d
            bj += d
          end
          bj += element.size
          res += element
        when PATCH_DIFF
          action, pa, pb, diff = change
          da = pa - ai
          db = pb - bj
          raise "Distances do not match!" if da != db
          if da > 0
            res += self[ai, da]
            ai += da
            bj += db
          end
          res << self[ai].stroke_patch(diff)
          ai += 1
          bj += 1
        end
      end
      d = self.size - ai
      res += self[ai, d] if d > 0
      res
    end
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
  
  32.times {
    from = gen_str(letters).split(//u)
    to   = gen_str(letters).split(//u)
   # p from
   # p to
   # p from.stroke_diff(to)
   # p from.stroke_patch(from.stroke_diff(to))
  #  puts "-"*40
  }
  1000.times {
    from = gen_str(letters).split(//u)
    to   = gen_str(letters).split(//u)
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

