module Math
  def self.bisect range, min_length
    left_positive = yield(range.min) > 0
    while (range.max-range.min) > min_length
      midpoint = Rational(range.max - range.min, 2) + range.min
      puts "midpoint = #{midpoint} = #{midpoint.to_f}"
      value = yield midpoint
      puts "f(midpoint) = #{value} = #{value.to_f}"
      if value == 0
        return value    #found exact answer
      elsif value > 0
        if left_positive
          range = midpoint..range.max
        else
          range = range.min..midpoint
        end
      elsif value < 0
        if left_positive
          range = range.min..midpoint
        else
          range = midpoint..range.max
        end
      end
    end
    range
  end
end