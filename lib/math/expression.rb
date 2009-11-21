# This is a first attempt at an object-oriented representation of some simple
# expressions. The idea is to be able to perform some simple simplification,
# expansion, and integration, as Maxima does. In retrospect, I probably
# should've found a way to interface with Maxima instead.

# You'll notice that it largely ignores the mathematical property of the
# problem I was analyzing, instead being as generic as is reasonable -- that
# is, while I've ommitted functionality not relevant to this problem, I've also
# made little progress in simplifying the problem in the general form. Instead,
# I've programmed the machine to clumsily and inefficiently simplify specific
# problems for me. A glance at Wikipedia shows that I could have very likely
# improved my results with one of _many_ algorithms for polynomial
# interpolation. I would still have needed a way to integrate them, however,
# and many of the other methods lose precision at some point -- I like to delay
# loss of precision as long as possible.

# A bug in the current integration: It doesn't integrate with respect to any variable
# It is therefore assuming that there is only a single variable in the expression,
# and integrates with respect to that variable. That's almost by design, but it won't
# complain if you try to integrate, for example, 2x + 3y with respect to x.

require 'rational'

class Expression
  attr_writer :sign
  
  def integration_error
    "I don't know how to integrate #{inspect}."
  end
  
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
  
  module CollectCompare
    def == other
      other.kind_of?(self.class) && other.terms == self.terms
    end
  end
  
  module Collection
    attr_reader :terms
    include CollectCompare
    def initialize *list
      if (list.length == 1) && list.first.kind_of?(Array)
        @terms = list.first
      else
        @terms = list
      end
    end
    def expand
      self.class.new self.terms.map(&:expand)
    end
    
    def simplify
      t = self.terms.map(&:simplify)
      block = proc{|t| t.kind_of? self.class}
      while t.any? &block
        t = t.reject(&block) +
            t.select(&block).map(&:terms).flatten
      end
      self.class.new(t)
    end
    
    def substitute vars
      self.class.new(terms.map{|t|t.substitute vars})
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
      other = wrap other
      if other.kind_of? Sum
        terms.inject(Term.new(0)) {|sum,term|
          other.terms.inject(sum) {|sum,other_term|
            sum + term*other_term
          }
        }
      elsif other.simple? || other.kind_of?(Symbol)
        Sum.new terms.map{|term| term * other}
      else
        super
      end
    end
    
    def + other
      if other.kind_of? Sum
        Sum.new(terms + other.terms)
      else
        Sum.new(terms+[other])
      end
    end
    
    def simplify
      sum = super.terms.reject {|term|
        (term.simple? && term.value == 0) ||
        (term.kind_of?(Collection) && term.terms.length == 0)
      }.inject(&:+)
      if sum.nil?
        Term.new 0
      elsif sum.kind_of? Sum
        if sum.terms.length == 1
          sum.terms.first
        else
          sum
        end
      else
        sum.simplify
      end
    end
    
    def integrate var
      Sum.new(terms.map{|t| t.integrate var})
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
    if other.kind_of?(Quotient) || other.kind_of?(Sum) || other.kind_of?(Product)
      other * self
    else
      Product.new(self, wrap(other))
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
        invert
      end
    end
    include SignBasedOnPositive
    def * other
      other = wrap(other)
      if other.kind_of? Product
        Product.new(self.terms+other.terms)
      else
        Product.new(self.terms+[other])
      end
    end
    def simplify
      new = super
      if new.terms.length == 1
        new.terms.first
      else
        a = new.terms.select(&:simple?).inject(&:*)
        not_a = new.terms.reject(&:simple?)
        unless not_a.nil?
          b = not_a.select{|t|t.kind_of? Symbol}
          b = b.sort{|a,b|a.value<=>b.value}.inject(&:*) unless b.nil?
          c = not_a.reject{|t|t.kind_of? Symbol}.inject(&:*)
        end
        product = [a,b,c].compact.inject(&:*)
        if product.kind_of? Product
          if product.terms.length == 1
            product.terms.first
          else
            product.strip
          end
        else
          product.simplify
        end
      end
    end
    def strip
      if (zero = terms.find {|term| term.simple? && term.value == 0})
        zero
      else
        Product.new(terms.reject{|term| term.simple? && term.value == 1})
      end
    end
    
    def integrate var
      simple = terms.select(&:simple?).inject(&:*)
      left = terms.reject(&:simple?)
      if left.length > 1
        raise integration_error
      else
        simple * left.first.integrate(var)
      end
    end
  end
  
  class Quotient < Expression
    include CollectCompare
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
      elsif t.first.simple? && t.first.value == 0
        t.first
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
    
    def substitute vars
      Quotient.new(*terms.map{|t|t.substitute vars})
    end
    
    def integrate var
      if denominator.simple?
        Quotient.new(numerator.integrate(var),denominator)
      else
        raise integration_error
      end
    end
    
    def / other
      Quotient.new(numerator,denominator*wrap(other))
    end
    # / stupid Kate bug.
  end
  
  module ValueCompare
    def == other
      other.kind_of?(self.class) && other.value == self.value
    end
  end
  
  class Symbol < Expression
    include ValueCompare
    attr_accessor :value
    def initialize value, sign=:positive
      self.value = value
      self.sign = sign
    end
    def inspect_inner
      self.value
    end
    def substitute vars
      if(result = vars[value])
        Term.new(result)
      else
        self
      end
    end
    def * other
      if other.kind_of?(Symbol) && other.value == value
        Power.new(self, wrap(2))
      else
        super
      end
    end
    
    def integrate var
      Power.new(self,wrap(1)).integrate var
    end
  end
  
  class Term < Expression
    include ValueCompare
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
    
    def substitute vars
      self
    end
    
    def integrate var
      self * wrap(var)
    end
    
    # Putting this at the bottom of the file, due to a bug in Kate's syntax highlighting.
    def / other
      other = wrap(other)
      other.simple? ? Term.new(Rational(self.value,other.value)) : super(other)
    end
  end
  
  # But this one seems to fix it. Close enough.
  def / other
    Quotient.new(self, wrap(other))
  end
  
  class Power < Expression
    include CollectCompare
    attr_accessor :base, :exponent
    def initialize n,d
      self.base, self.exponent = n, d
    end
    def terms
      [base, exponent]
    end
    
    def expand
      Product.new(exponent.times.map{|x| base})
    end
    
    def simplify
      t = terms.map(&:simplify)
      if t.all?(&:simple?)
        wrap(t.first.value ** t.last.value)
      else
        self
      end
    end
    
    def * other
      if other == base
        Power.new(self.base,self.exponent+1)
      else
        super
      end
    end
    
    def substitute vars
      Power.new(*terms.map{|t|t.substitute vars})
    end
    
    def inspect_inner
      "#{base.inspect}^#{exponent.inspect}"
    end
    
    def integrate var
      if base == wrap(var) && exponent.simple?
        new_exponent = exponent + 1
        raise integration_error unless new_exponent.simple? && (new_exponent.value != 0)
        Power.new(base,new_exponent) / new_exponent
      else
        raise integration_error
      end
    end
  end
  
  def ** other
    Power.new(self,wrap(other))
  end
  alias ^ **
end