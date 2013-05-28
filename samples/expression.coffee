_ = require('underscore')
{solve, special, vari, dummy, cons, vari, macro} = require("../lib/dao")
{print_, getvalue, toString} = require("../lib/builtins/general")
{andp, orp, rule, bind, is_} = require("../lib/builtins/logic")
{begin} = require("../lib/builtins/lisp")
{settext, char, digits, spaces, eoi, literal, number, dqstring, sqstring} = require("../lib/builtins/parser")


exports.expression = (operator) -> rule(null, 'expression', (x)->
  op = vari('op'); e1 = vari('e1'); e2 = vari('e2')
  [[expr(f, e1, e2)], andp(expression(e1), operator(f), expression(e2))]
  )

# use rule. slower
exports.operator = rule(1, 'operator', (x) ->
  [ ['+'], literal('+'),
    ['-'], literal('-'),
    ['*'], literal('*'),
    ['/'], literal('/')
  ])

# use special, speed optimization
exports.operator = special('operator', (solver, cont, x) -> (v) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(false)
  c = data[pos]
  x = solver.trail.deref(x)
  if _.isString(x)
    if x is c
      solver.state = [data, pos+1]; cont(c)
    else solver.failcont(c)
  else
    if c in "+-*/" then x.bind(c, solver.trail); solver.state = [data, pos+1]; cont(c)
    else solver.failcont(c))

# use terminal in parser.coffee
operator = (x) -> is_(charIn("+-*/"))

string = (x) -> orp(is_(x, dqstring), is_(sqstring))
exports.atom = rule(1, 'atom', (x) ->
  [ [x], number(x),
    [x], string(x),
    [x], literal('(') + spaces + expression(x) + literal(')')
  ])