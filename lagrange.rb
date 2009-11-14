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