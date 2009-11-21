require 'math/expression'

# Finds the Lagrange Polynomial (as an Expression) for the given points
def Math.lagrange points
  x = Expression.wrap :x
  zero = Expression.wrap 0
  one = Expression.wrap 1
  points.inject(zero) {|sum, j|
    points.inject(one) {|product, i|
      if i == j
        product
      else
        product * ((x - Expression.wrap(i.first)) /
          (Expression.wrap(j.first) - Expression.wrap(i.first)))
      end
    } * j.last + sum
  }
end

# Calculates an integral (definite or not) for the given points.
# The indefinite integral given doesn't include c.
def Math.lagrange_integral points, range=nil
  # It's not easy to explain why this works the way it does.
  integral = Math.lagrange(points).simplify.expand.simplify.integrate :x
  if range
    # Definite integration
    result = (integral.substitute(:x => range.max) -
              integral.substitute(:x => range.min)).simplify
    raise "Substitution failed!" unless result.simple?
    result.value
  else
    # Indefinite integration
    integral.simplify
  end
end