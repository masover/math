class Expression
  attr_writer :sign
  
  def simple?; false; end
  
  def self.wrap other
    if other.kind_of? Expression
      other
    elsif other.kind_of? ::Symbol
      Symbol.new(other)
    else
      Term.new(other)
    end
  end
  def wrap other
    Expression.wrap other
  end
  
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
  
  def invert
    Product.new([Term.new(-1), self])
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
    def initialize *list
      @terms = list
    end
  end
  
  def + other
    other = Term.new(other) unless other.kind_of? Expression
    Sum.new(self,wrap(other))
  end
  def - other
    self + wrap(other) * (-1)
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
  
  def * other
    Product.new(self, wrap(other))
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
        invert
      end
    end
    include SignBasedOnPositive
    def * other
      other = wrap(other)
      if other.simple?
        Product.new(terms.first*other,*terms[1..terms.length])
      else
        super(other)
      end
    end
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
      t = terms.map(&:simplify)
      if t.all?(&:simple?)
        Term.new(Rational(*t.map(&:value)))
      elsif terms.all?(&:negative?)
        Difference.new(*t.map(&:invert))
      else
        self
      end
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
    def invert
      Term.new(-value)
    end
    
    def + other
      other = wrap(other)
      other.simple? ? Term.new(self.value+other.value) : super(other)
    end
    def * other
      other = wrap(other)
      other.simple? ? Term.new(self.value*other.value) : super(other)
    end
    
    # Putting this at the bottom of the file, due to a bug in Kate's syntax highlighting.
    def / other
      other = wrap(other)
      other.simple? ? Term.new(Rational(self.value,other.value)) : super(other)
    end
  end
  
  # Also at the bottom of the file, because of the same bug.
  def / other
    Quotient.new(self, wrap(other))
  end
end