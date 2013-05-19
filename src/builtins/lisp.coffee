# lispt.coffee don't know trail, failcont, state and like.
# lisp know cont only.

_ = require('underscore')
solve = require "../../src/solve"
general = require "../../src/builtins/general"

special = solve.special
macro = solve.macro
debug = solve.debug

exports.quote = special('quote', (solver, cont, exp) ->
    (v, solver) -> cont(exp, solver))

exports.eval_ = special('eval', (solver, cont, exp) ->
  solver.cont(exp, (v, solver) -> [solver.cont(v, cont), null, solver]))

exports.assign = special('assign', (solver, cont, vari, exp) ->
  # different from is_ in logic.coffee:
  # Because not using vari.bind, this is not saved in solver.trail and so it can NOT be restored in solver.failcont
  # EXCEPT the vari has been in solver.trail in the logic branch before.
  solver.cont(exp, (v, solver) -> (vari.binding = v; [cont, v, solver])))

exports.begin = special('begin', (solver, cont, exps...) -> solver.expsCont(exps, cont))

if_fun = (solver, cont, test, then_, else_) ->
  then_cont = solver.cont(then_, cont)
  if else_?
    else_cont = solver.cont(else_, cont)
    solver.cont(test, (v, solver) ->
      if (v) then then_cont(v, solver)
      else else_cont(v, solver))
  else
    solver.cont(test, (v, solver) ->
      if (v) then then_cont(null, solver)
      else cont(null, solver))

exports.if_ = special('if_', if_fun)

iff_fun = (solver, cont, clauses, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    [test, then_] = clauses[0]
    if_fun(solver, cont, test, then_, else_)
  else
    [test, then_] = clauses[0]
    then_cont = solver.cont(then_, cont)
    iff_else_cont = iff_fun(solver, cont, clauses[1...], else_)
    solver.cont(test, (v, solver) ->
      if (v) then [then_cont, v, solver]
      else [iff_else_cont, v, solver])

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

exports.block = block = special('block', (solver, cont, label, body...) ->
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

exports.break_ = break_ = special('break_', (solver, cont, label='', value=null) ->
  if value != null and not _.isString label then throw new TypeError([label, value])
  if value is null and not _.isString label then (value = label; label = '')
  exits = solver.exits[label]
  if not exits or exits==[] then throw Error(label)
  exitCont = exits[exits.length-1]
  solver.cont(value, (v, solver) ->
    solver.protect(exitCont)(v, solver)))

exports.continue_ = continue_ = special('continue_', (solver, cont, label='') ->
  continues = solver.continues[label]
  if not continues or continues==[] then throw Error(label)
  continueCont = continues[continues.length-1]
  (v, solver) -> [solver.protect(continueCont[0]), v, solver])

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

exports.catch_ = special('catch_', (solver, cont, tag, forms...) ->
  solver.cont(tag, (v, solver) ->
    solver.pushCatch(v, cont)
#    debug 'catch', v
    formsCont = solver.expsCont(forms, (v2, solver) -> solver.popCatch(v); [cont, v2, solver])
    [formsCont, v, solver]))

exports.throw_ = special('throw_', (solver, cont, tag, form) ->
#  debug  1233
  formCont =  (v, solver) -> solver.cont(form, (v2, solver) ->
#    debug 'throw', v, v2
    solver.protect(solver.findCatch(v))(v2, solver))(v, solver)
  solver.cont(tag, formCont))

exports.protect = special('protect', (solver, cont, form, cleanup...) ->
  oldprotect = solver.protect
  solver.protect = (fun) -> (v1, solver) ->
                               solver.expsCont(cleanup, (v2, solver) ->
                                 solver.protect = oldprotect;
                                 oldprotect(fun)(v1, solver))(v1, solver)
  cleanupCont = (v1, solver) ->
    solver.expsCont(cleanup, (v2, solver) ->
                    solver.protect = oldprotect
                    cont(v1, solver))(v1, solver)
  result = solver.cont(form, cleanupCont)
  result)

exports.callcc = special('callcc', (solver, cont, fun) -> (v, solver) ->
  result = fun(cont)[1]
  solver.done = false
  cont(result, solver))

exports.callfc = special('callfc', (solver, cont, fun) -> (v, solver) ->
  result = fun(solver.failcont)[1]
  solver.done = false
  cont(result, solver))

exports.quasiquote = exports.qq = special('quasiquote', (solver, cont, item) ->
  solver.quasiquote?(item, cont))

exports.unquote = exports.uq = special('unquote', (solver, cont, item) ->
  throw "unquote: too many unquote and unquoteSlice" )

exports.unquoteSlice = exports.uqs = special('unquoteSlice', (solver, cont, item) ->
  throw "unquoteSlice: too many unquote and unquoteSlice")
