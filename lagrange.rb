require File.join(File.dirname(__FILE__),'expression')

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

def Math.lagrange_integral points, range=nil
  # It's not easy to explain why this works the way it does.
  integral = Math.lagrange(points).simplify.expand.simplify.integrate
  if range
    result = (integral.substitute(:x => range.max) - integral.substitute(:x => range.min)).simplify
    raise "Substitution failed!" unless result.simple?
    result.value
  else
    integral.simplify
  end
end