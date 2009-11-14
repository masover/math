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
  def expand
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
      if (list.length == 1) && list.first.kind_of?(Array)
        @terms = list.first
      else
        @terms = list
      end
    end
    def simplify
      self.class.new self.terms.map(&:simplify)
    end
    def expand
      self.class.new self.terms.map(&:simplify)
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
    
    def * other
      if other.kind_of? Sum
        terms.inject(Term.new(0)) {|sum,term|
          other.terms.inject(sum) {|sum,other_term|
            sum + term*other_term
          }
        }
      else
        super
      end
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
      elsif other.kind_of? Product
        Product.new(self.terms+other.terms)
      else
        super(other)
      end
    end
    def simplify
      if terms.length == 1
        terms.first
      else
        product = terms.inject(&:*)
        if product.kind_of? Product
          if product.terms.length == 1
            product.terms.first
          else
            product
          end
        else
          product.simplify
        end
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
      elsif t.all?(&:negative?)
        Quotient.new(*t.map(&:invert)).simplify
      else
        new = Quotient.new(*t)
        if new.numerator.kind_of? Quotient
          Quotient.new(new.numerator.numerator,
                       new.denominator*new.numerator.denominator
                      ).simplify
        elsif new.denominator.kind_of? Quotient
          Quotient.new(new.numerator*new.denominator.denominator,
                       new.denominator.numerator
                      ).simplify
        elsif t.all?{|t|t.kind_of? Product}
          common = new.numerator.terms & new.denominator.terms
          if common.length > 0
            Quotient.new(Product.new(new.numerator.terms - common),
                         Product.new(new.denominator.terms - common)
                        ).simplify
          else
            new
          end
        elsif new.numerator.kind_of?(Product) &&
              new.denominator.kind_of?(Term) &&
              new.numerator.terms.include?(new.denominator)
          Quotient.new(Product.new(new.numerator.terms - [new.denominator]),
                       new.denominator
                      ).simplify
        elsif new.numerator.kind_of?(Term) &&
              new.denominator.kind_of?(Product) &&
              new.denominator.terms.include?(new.numerator)
          Quotient.new(new.numerator,
                       Product.new(new.denominator.terms - [new.numerator])
                      ).simplify
        else
          new
        end
      end
    end
    
    def expand
      if numerator.kind_of? Sum
        Sum.new(numerator.terms.map {|term|
          Quotient.new(term,denominator)
        })
      else
        self
      end
    end
    
    def * other
      Quotient.new(numerator*wrap(other),denominator)
    end
    
    def / other
      Quotient.new(numerator,denominator*wrap(other))
    end
    # / stupid Kate bug.
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