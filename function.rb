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
end

F = Math::Function