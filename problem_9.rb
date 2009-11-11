require 'sinatra'
require File.join(File.dirname(__FILE__),'function')

f = Math::Function.new {|x| Math::E**(-x**2)}
syms = %w(midpoint trapezoid simpson).map(&:to_sym)

get '/' do
  "<html><head><style type='text/css'>
  td {font-family: monospace}
  </style></head><body>
  <table border>
  <tr>
    <th>n</th>#{syms.map {|sym| "<th>#{sym}</th>"}.join}
  </tr>
  #{
    [10,20,50].map {|n|
      "<tr><th>#{n}</th>#{
        syms.map {|sym|
          '<td>%.14f</td>' % f.send(sym, 0, 2, n)
        }.join
      }</tr>"
    }.join
  }</table>"
end