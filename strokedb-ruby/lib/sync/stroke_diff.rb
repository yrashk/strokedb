require 'rubygems'
require 'diff/lcs'

module StrokeDB
  PATCH_REPLACE      = 'R'.freeze
  PATCH_STRING       = 'S'.freeze
  
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

      # lcs_diff     -> [ [Change, Change, ...], ... ]
      lcs_diff = Diff::LCS.diff(self, to)
      patchset = lcs_diff.map do |changes| 
        # 1. Deletion
        d_i1 = nil
        d_i2 = nil
        change = nil
        
        # BUG HERE!
        chs = changes.dup
        while change = chs.shift
          if change.action == '-' && change.element != ''  # it can be ["-", pos, ""] (empty string)
            d_i1 ||= change.position
            d_i2 = change.position
          end
        end

        # put shifted item back if it is '+'
        changes.unshift(change) if change && change.action == '+'

        # 2. Insertion
        i_i1 = nil
        new_sequence = nil
        unless changes.empty?
          new_sequence = changes.inject(""){|r,c| r << c.element; r }
          i_i1 = changes[0].position
        end

        # 3. Determine kind of change
        if i_i1
          if d_i1
            [PATCH_STRING+'r', d_i1, d_i2 - d_i1 + 1, new_sequence]
          else
            [PATCH_STRING+'i', i_i1, 0,               new_sequence]
          end
        else
          if d_i1
            [PATCH_STRING+'d', d_i1, d_i2 - d_i1 + 1, ""]
          else
            raise "Diffed equal strings, oh my!"
            nil # no difference
          end
        end
      end.compact
      patchset.empty? ? nil : patchset
    end
    def stroke_patch(patch)
      return self unless patch
      offset = 0
      patch.inject(self.dup) do |to, change|
        t, i, len, s = change
        to[i + offset, len] = s
        offset += s.size - len
        to
      end
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
  
  letters = %w(a b c d)
  def gen_str(letters)
    str = ""
    len = rand(letters.size + 1)
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
      p from
      p to
      puts "-"*40
    end
  }  
  p 
  
end

