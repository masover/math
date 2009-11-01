module Math
  def self.reimann a, b, n
    # As a matter of convenience, force a < b.
    # If a == b, there's no hope for you.
    if a > b
      a,b = b,a
    end
    delta = Rational(b-a,n)
    right = a + delta
    right_sum = (right_value = yield right)
    mid = a + (delta/2)
    mid_sum = yield mid
    # So this is precise -- right == b when it's supposed to,
    # because all x-values are kept as integers or rationals.
    while right < b
      mid += delta
      mid_sum += yield mid
      right += delta
      right_sum += (right_value = yield right)
    end
    # Given either the left sum or the right sum, we can
    # simply pop one off the right and add one to the left.
    left_sum = right_sum - right_value + yield(a)
    [left_sum*delta, mid_sum*delta, right_sum*delta]
  end
end