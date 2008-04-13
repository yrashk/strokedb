unless defined?(BlankSlate)
  class BlankSlate < BasicObject; end if defined?(BasicObject)

  class BlankSlate
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end
end

class BlankSlate
  MethodMapping = {
    '[]' => 'squarebracket',
    '[]=' => 'squarebracket_set',
    '<<' => 'leftarrow',
    '*' => 'star',
    '+' => 'plus',
    '-' => 'minus',
    '&' => 'bitwiseand',
    '|' => 'bitwiseor',
    '<=>' => 'spaceship',
    '==' => 'equalequal',
    '===' => 'tripleequal',
    '=~' => 'regexmatch',
    '`'  => 'backtick',
  } unless defined? MethodMapping
end

def BlankSlate superclass = nil
  if superclass
    (@blank_slates ||= {})[superclass] ||= Class.new(superclass) do
      instance_methods.sort.each { |m|
        unless m =~ /^__/
          mname = "__#{::BlankSlate::MethodMapping[m.to_s] || m}"
          class_eval "alias :'#{mname}' :'#{m}'" 
          
          undef_method m
        end
      }
    end
  else
    BlankSlate
  end
end
