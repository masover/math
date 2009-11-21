Gem::Specification.new do |s|
  s.name = 'math'
  s.version = '0.0.1'
  s.date = '2009-11-21'
  s.summary = 'Random mathematical tools built for a calculus class'
  s.email = 'ninja@slaphack.com'
  s.homepage = 'http://github.com/masover/math'
  s.description = 'Contains various forms of numeric integration, as well as a simple expression library for manipulating algebraic equations.'
  s.has_rdoc = false
  s.authors = ['David Masover']
  s.files = %w(expression function lagrange).map{|f|"lib/math/#{f}.rb"}.push 'bin/math_irb'
  s.executables = 'math_irb'
end