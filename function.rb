# An implementation of a function whose values are cached

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
end

def F *args, &block
  Math::Function.new *args, &block
end