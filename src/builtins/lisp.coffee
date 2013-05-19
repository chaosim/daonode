# lispt.coffee don't know trail, failcont, state and like.
# lisp know cont only.

_ = require('underscore')
solve = require "../../src/solve"
general = require "../../src/builtins/general"

solver = solve.solver
special = solve.special
macro = solve.macro
debug = solve.debug

exports.quote = special('quote', (cont, exp) ->  -> solver.value = exp; cont())

exports.eval_ = special('eval', (cont, exp) ->
  solver.cont(exp, -> solver.cont(solver.value, cont)))

exports.assign = special('assign', (cont, vari, exp) ->
  # different from is_ in logic.coffee:
  # Because not using vari.bind, this is not saved in solver.trail and so it can NOT be restored in solver.failcont
  # EXCEPT the vari has been in solver.trail in the logic branch before.
  solver.cont(exp, -> (vari.binding = solver.value; cont)))

exports.begin = special('begin', (cont, exps...) -> solver.expsCont(exps, cont))

if_fun = (cont, test, then_, else_) ->
  then_cont = solver.cont(then_, cont)
  else_cont = solver.cont(else_, cont)
  solver.cont(test, ->
    if (solver.value) then then_cont()
    else else_cont())

exports.if_ = special('if_', if_fun)

iff_fun = (cont, clauses, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    [test, then_] = clauses[0]
    if_fun(cont, test, then_, else_)
  else
    [test, then_] = clauses[0]
    then_cont = solver.cont(then_, cont)
    iff_else_cont = iff_fun(cont, clauses[1...], else_)
    solver.cont(test, ->
      if (solver.value) then then_cont()
      else iff_else_cont())

exports.iff = special('iff', iff_fun)

### iff's macro version
iff = macro (clauses_, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    exports.if_(clauses[0][0], clauses[0][1], else_)
  else
     exports.if_(clauses[0][0], clauses[0][1], iff(clauses[1...], else_)
###

exports.block = block = special('block', (cont, label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat(body))

  exits = solver.exits[label] ?= []
  exits.push(cont)
  defaultExits = solver.exits[''] ?= []  # if no label, go here
  defaultExits.push(cont)
  holder = [null]
  continues = solver.continues[label] ?= []
  continues.push(holder)
  defaultContinues = solver.continues[''] ?= []   # if no label, go here
  defaultContinues.push(holder)
  holder[0] = fun = solver.expsCont(body, cont)
  exits.pop()
  if exits.length is 0 then delete solver.exits[label]
  continues.pop()
  if continues.length is 0 then delete solver.continues[label]
  defaultExits.pop()
  defaultContinues.pop()
  fun)

exports.break_ = break_ = special('break_', (cont, label='', value=null) ->
  if value != null and not _.isString label then throw new TypeError([label, value])
  if value is null and not _.isString label then (value = label; label = '')
  exits = solver.exits[label]
  if not exits or exits==[] then throw Error(label)
  exitCont = exits[exits.length-1]
#  solver.cont(value, -> solver.protect(exitCont)()))
  solver.cont(value, -> exitCont()))

exports.continue_ = continue_ = special('continue_', (cont, label='') ->
  continues = solver.continues[label]
  if not continues or continues==[] then throw Error(label)
  continueCont = continues[continues.length-1]
#  ->  solver.protect(continueCont[0])())
  ->  continueCont[0]())

not_ = general.not_

exports.loop_ = macro('loop', (label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat body)
  block(label, body.concat([continue_(label)])...))

exports.while_ = macro('while_', (label, test, body...) ->
  if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
  block(label, [if_(not_(test), break_(label))].concat(body).concat([continue_(label)])...))

exports.until_ = macro('until_', (label,body..., test) ->
   if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
   body = body.concat([if_(not_(test), continue_(label))])
   block(label, body...))

exports.catch_ = special('catch_', (cont, tag, forms...) ->
  solver.cont(tag, ->
    v1 = solver.value
    solver.pushCatch(v1, cont)
    formsCont = solver.expsCont(forms, -> solver.popCatch(v1); cont())
    formsCont()))

exports.throw_ = special('throw_', (cont, tag, form) ->
  solver.cont(tag, ->
    v = solver.value
    solver.cont(form, -> solver.protect(solver.findCatch(v))())()))

exports.protect = special('protect', (cont, form, cleanup...) ->
  oldprotect = solver.protect
  solver.protect = (fun) -> ->
    value = solver.value
    solver.expsCont(cleanup, ->
      solver.protect = oldprotect;
      solver.value = value
      oldprotect(fun)())()
  solver.cont(form, ->
    formValue = solver.value
    solver.expsCont(cleanup, ->
      solver.protect = oldprotect
      solver.value = formValue
      cont())()))

runner = (cont) -> ->
  d = solver.done
  solver.done = false
  while not solver.done then cont = cont()
  solver.done = d
  solver.value

exports.callcc = special('callcc', (cont, fun) -> ->
  solver.value = fun(runner(cont))
  solver.done = false
  cont())

exports.callfc = special('callfc', (cont, fun) -> ->
  solver.value = fun(runner(solver.failcont))
  solver.done = false
  cont())

exports.quasiquote = exports.qq = special('quasiquote', (cont, item) ->
  solver.quasiquote?(item, cont))

exports.unquote = exports.uq = special('unquote', (cont, item) ->
  throw "unquote: too many unquote and unquoteSlice" )

exports.unquoteSlice = exports.uqs = special('unquoteSlice', (cont, item) ->
  throw "unquoteSlice: too many unquote and unquoteSlice")
