#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'function')
require File.join(File.dirname(__FILE__), 'expression')

def F *args, &block
  Math::Function.new *args, &block
end

E = Object.new
def E obj
  Expression.wrap(obj)
end
def E.+ other
  E other
end
def E.- other
  E(-1) * other
end
def E.* other
  E other
end
def E./ other
  E(1) / other
end

module Kernel
  def e
    Math::E
  end
  def pi
    Math::PI
  end
end

require 'irb'
require 'irb/completion'
IRB.start __FILE__