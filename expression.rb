class Expression
  attr_writer :sign
  
  def simple?; false; end
  
  def simplify
    self
  end
  
  def sign
    @sign ||= :positive
  end
  
  def positive?
    sign == :positive
  end
  def negative?
    sign == :negative
  end
  
  def inspect
    if positive?
      inspect_inner
    else
      "(-#{inspect_inner})"
    end
  end
  
  module Collection
    attr_reader :terms
    def initialize t=[]
      @terms = t
    end
  end
  
  class Sum < Expression
    include Collection
    def inspect_inner
      "(#{terms.map(&:inspect).join '+'})"
    end
  end
  
  module SignBasedOnPositive
    def negative?
      !positive?
    end
    def sign
      positive? ? :positive : :negative
    end
  end
  
  class Product < Expression
    include Collection
    def inspect
      "(#{terms.map(&:inspect).join '*'})"
    end
    def positive?
      terms.inject(true){|s,t| s == t.positive?}
    end
    def abs
      if positive?
        self
      else
        Product.new terms.dup.push(-1)
      end
    end
    include SignBasedOnPositive
  end
  
  class Quotient < Expression
    attr_accessor :numerator, :denominator
    def initialize n,d
      self.numerator, self.denominator = n, d
    end
    def terms
      [numerator, denominator]
    end
    def inspect
      "(#{terms.map(&:inspect).join '/'})"
    end
    def positive?
      numerator.sign == denominator.sign
    end
    include SignBasedOnPositive
    
    def simplify
      if terms.all?(&:simple?)
        Term.new(Rational(numerator,denominator))
      elsif terms.all?(&:negative?)
        Difference.new(numerator.abs,denominator.abs)
      else
        self
      end
    end
  end
  
  class Term < Expression
    attr_reader :value
    
    def simple?; true; end
    
    def value= v
      self.sign = if v.respond_to? :sign
        v.sign
      elsif v.respond_to? :positive?
        v.positive? ? :positive : :negative
      else
        (v < 0) ? :negative : :positive
      end
      @value = v
    end
    
    def initialize v
      self.value = v
    end
    
    def inspect_inner
      value.abs.inspect
    end
    
    def abs
      Term.new(value.abs)
    end
  end
  
  class Symbol < Expression
    attr_accessor :value
    def initialize value, sign=:positive
      self.value = value
      self.sign = sign
    end
    def inspect_inner
      self.value
    end
  end
end