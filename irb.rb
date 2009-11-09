#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'function')

def F *args, &block
  Math::Function.new *args, &block
end

require 'irb'
require 'irb/completion'
IRB.start __FILE__