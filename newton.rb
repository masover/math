module Math
  def self.newton f, f_prime, x=0, precision=5
    n = 0
    last_string = nil
    sprintf_format = "%0.#{precision}f"
    while (string = sprintf(sprintf_format, x)) != last_string
      puts "x#{n} = #{string} = #{x}"
      x = x - (f.call(x))/(f_prime.call(x))
      n += 1
      last_string = string
    end
    x
  end
end