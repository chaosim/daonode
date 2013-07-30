_ = require "underscore"

{solve} = core = require('./core')
{string, char, number, parsetext, quoteString, identifier
begin, nonlocal, direct
jsfun, lamda, funcall
andp, orp, assign, array} = util = require('./util')

{operator} = daoutil = require('./daoutil')

il = require('./interlang')

repl = () ->

exports.compile = compile = (code) ->
  sexpr = core.solve(parsetext(grammar, string(exp)))
  path = process.cwd()+'/lib/compiled.js'
  core.compile(sexpr, path)

exports.solve = solve = (exp) ->
  sexpr = core.solve(parsetext(grammar, string(exp)))
  core.solve(sexpr)

solver = 'solver'
x = 'x'; y = 'y'; z = 'z'
op = 'op'
atomExpr = 'atomExpr'; unaryExpr = 'unaryExpr'; binaryExpr = 'binaryExpr'

grammar = begin(
  direct(il.begin(
    il.assign(il.uservar('daoutil'), il.require('./daoutil')),
    il.assign(il.uservar('binaryOperator'), il.attr(il.uservar('daoutil'), il.symbol('binaryOperator'))),
    il.assign(il.uservar('unaryOperator'), il.attr(il.uservar('daoutil'), il.symbol('unaryOperator'))),
    il.assign(il.uservar('suffixOperator'), il.attr(il.uservar('daoutil'), il.symbol('suffixOperator'))))),
  assign(atomExpr, lamda([], orp(identifier(), quoteString(), number()))),
  assign(unaryExpr, lamda([],
      orp(andp(assign(op, funcall('unaryOperator', solver)),
               assign(x, funcall(atomExpr)),
               array(op, x)),
          andp(assign(x, funcall(atomExpr)),
              orp(andp(assign(op, funcall('suffixOperator', solver)), array(op, x)),
                  x)))))
  assign(binaryExpr, lamda([],
     andp(assign(x, funcall(atomExpr)),
          orp(andp(assign(op, funcall('binaryOperator', solver)),
                   assign(y, funcall(atomExpr)),
                   array(op, x, y)),
              x)))),
  funcall(binaryExpr))


