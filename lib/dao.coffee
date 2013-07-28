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
#  core.solve(sexpr)

unaryExpr = (exp) -> andp(unaryOperator(op), expression(exp))

grammar = begin(
  direct(il.begin(
    il.assign(il.uservar('daoutil'), il.require('./daoutil')),
    il.assign(il.uservar('operator'), il.attr(il.uservar('daoutil'), il.symbol('operator')))))
  assign('atomic', lamda([], orp(identifier(), quoteString(), number()))),
  assign('binaryExpr', lamda([],
     andp(assign('x', funcall('atomic')),
          orp(andp(assign('op', funcall('operator', 'solver')),
                   assign('y', funcall('atomic')),
                   array('op', 'x', 'y')),
              'x')))),
  funcall('binaryExpr'))


