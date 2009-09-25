module Math
  def self.secant a, b
    # force a to be the larger one
    a, b = b, a if b > a
    (yield(a) - yield(b)) / (a - b)
  end
end