class Float
  ::Infinity = 1.0 / 0.0 unless defined? ::Infinity
  ::NaN      = 0.0 / 0.0 unless defined? ::NaN
end
