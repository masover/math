class Expression
  attr_writer :terms, :sign
  def terms
    @terms ||= []
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
  
  class Sum < Expression
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
    def inspect
      "(#{terms.map(&:inspect).join '*'})"
    end
    def positive?
      terms.inject(true){|s,t| s == t.positive?}
    end
    include SignBasedOnPositive
  end
  
  class Difference < Expression
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
  end
  
  class Term < Expression
    undef_method :terms
    attr_reader :value  
    
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
  end
end