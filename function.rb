# An implementation of a mathematical function whose values are cached
# and a number of useful operations which can be performed on a function.

class Math::Function < Proc
  attr_reader :values
  def initialize *args, &block
    @values = Hash.new do |hash, key|
      hash[key] = old_call *key
    end
    super
  end
  
  # Procs don't seem to support blocks. Oh well.
  alias old_call call
  def call *args
    self.values[args]
  end
  alias [] call
  
  # Base class for Reimann sums. Uses left-endpoint evaluation by default.
  class Reimann
    # As a matter of convenience, force a < b.
    # If a == b, there's no hope for you.
    def initialize function, a, b, n
      self.function = function
      if a > b
        a,b = b,a
      end
      self.a = a
      self.b = b
      self.n = n
      self.sum = 0
    end
    attr_accessor :function,:a,:b,:n,:sum
    def f *args
      function[*args]
    end
    def run
      n.times.inject(init_loop,&method(:run_loop))
      end_loop
    end
    alias init_loop a
    def run_loop x, i
      self.sum += f(x)
      increment x
    end
    def increment x
      x+delta
    end
    def end_loop
      self.sum*delta
    end
    def delta
      @delta ||= Rational(b-a,n)
    end
  end
  def reimann a,b,n
    Reimann.new(self,a,b,n).run
  end
  
  # Identical to left evaluation, but push over one.
  class RightReimann < Reimann
    def init_loop
      a+delta
    end
  end
  def right_reimann a,b,n
    RightReimann.new(self,a,b,n).run
  end
  
  # Identical, but push over only half the delta.
  class MidReimann < Reimann
    def init_loop
      a+(delta/2)
    end
  end
  def midpoint a,b,n
    MidReimann.new(self,a,b,n).run
  end
  
  class Trapezoid < Reimann
    def run_loop x,i
      right = increment x
      self.sum+=f(x)+f(right)
      right
    end
    def end_loop
      super/2
    end
  end
  def trapezoid a,b,n
    Trapezoid.new(self,a,b,n).run
  end
  
  class Simpson < Reimann
    # Because we're doing n times, halving n.
    def n= value
      @n = value/2
    end
    def init_loop
      right = a + delta
      mid = a + (delta/2)
      left = a
      [left,mid,right]
    end
    def run_loop a, i
      left,mid,right = a
      self.sum += f(left) + 4*f(mid) + f(right)
      [right,mid+delta,right+delta]  #increment
    end
    def end_loop
      super/6
    end
  end
  def simpson a,b,n
    Simpson.new(self,a,b,n).run
  end
  
  def bisect range, min_length
    left_positive = self[range.min] > 0
    while (range.max-range.min) > min_length
      midpoint = Rational(range.max - range.min, 2) + range.min
      puts "midpoint = #{midpoint} = #{midpoint.to_f}"
      value = self[midpoint]
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
  
  # I could compute the derivative, but Maxima can do it for me.
  # Still, I may return to this sometime and actually parse the given block.
  attr_accessor :derivative
  def newton x=0, precision=5
    n = 0
    last_string = nil
    sprintf_format = "%0.#{precision}f"
    while (string = sprintf(sprintf_format, x)) != last_string
      puts "x#{n} = #{string} = #{x}"
      x = x - self[x]/derivative[x]
      n += 1
      last_string = string
    end
    x
  end
  
  def self.secant a, b
    # force a to be the larger one
    a, b = b, a if b > a
    (self[a] - self[b]) / (a - b)
  end
end