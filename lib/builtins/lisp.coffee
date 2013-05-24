# lispt.coffee don't know trail, failcont, state and like.
# lisp know cont only.

_ = require('underscore')
solve = require "../dao"
general = require "./general"

special = solve.special
macro = solve.macro

debug = solve.debug

### aka lisp's quote, like in lisp, 'x==x, quote(x) === x ###
exports.quote = special(1, 'quote', (solver, cont, exp) ->
    (v, solver) -> cont(exp, solver))

### aka lisp's eval, solve(eval_(quote(x))) means solve(x),  ###
exports.eval_ = special(1, 'eval', (solver, cont, exp) ->
  solver.cont(exp, (v, solver) -> [solver.cont(v, cont), null, solver]))

### vari.binding = exp ###
exports.assign = special(2, 'assign', (solver, cont, vari, exp) ->
  # different from is_ in logic.coffee:
  # Because not using vari.bind, this is not saved in solver.trail and so it can NOT be restored in solver.failcont
  # EXCEPT the vari has been in solver.trail in the logic branch before.
  solver.cont(exp, (v, solver) -> (vari.binding = v; cont(v, solver))))

### vari.binding = 0
  provide this for reducing continuation, and make code running faster. ###
exports.zero = special(1, 'zero', (solver, cont, vari, exp) ->
  (v, solver) -> (vari.binding = 0; cont(v, solver)))

### vari.binding = 1
  provide this for reducing continuation, and make code running faster. ###
exports.one = special(1, 'one', (solver, cont, vari, exp) ->
 (v, solver) -> (vari.binding = 1; cont(v, solver)))

### aka lisp's begin, same as logic.andp ###
exports.begin = special(null, 'begin', (solver, cont, exps...) -> solver.expsCont(exps, cont))

if_fun = (solver, cont, test, then_, else_) ->
  then_cont = solver.cont(then_, cont)
  if else_?
    else_cont = solver.cont(else_, cont)
    action = (v, solver) ->
      if (v) then then_cont(v, solver)
      else else_cont(v, solver)
    solver.cont(test, action)
  else
    action =  (v, solver) ->
      if (v) then then_cont(null, solver)
      else cont(null, solver)
    solver.cont(test, action)

### lisp style if.
  different from logic.ifp, when test fail, it do not run else_ clause.  ###
exports.if_ = special([2,3], 'if_', if_fun)

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
    action = (v, solver) ->
      if (v) then [then_cont, v, solver]
      else [iff_else_cont, v, solver]
    solver.cont(test, action)

###
iff [ [test1, body1],
      [test2, body2]
    ]
    else_
###
exports.iff = special(-2, 'iff', iff_fun)

### lisp style block ###
exports.block = block = special(null, 'block', (solver, cont, label, body...) ->
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

### break a block ###
exports.break_ = break_ = special([0, 1,2], 'break_', (solver, cont, label='', value=null) ->
  if value != null and not _.isString label then throw new TypeError([label, value])
  if value is null and not _.isString label then (value = label; label = '')
  exits = solver.exits[label]
  if not exits or exits==[] then throw Error(label)
  exitCont = exits[exits.length-1]
  valCont = (v, solver) -> solver.protect(exitCont)(v, solver)
  solver.cont(value, valCont))

### continue a block ###
exports.continue_ = continue_ = special([0,1], 'continue_', (solver, cont, label='') ->
  continues = solver.continues[label]
  if not continues or continues==[] then throw Error(label)
  continueCont = continues[continues.length-1]
  (v, solver) -> [solver.protect(continueCont[0]), v, solver])

not_ = general.not_

### loop ###
exports.loop_ = macro(null, 'loop', (label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat body)
  block(label, body.concat([continue_(label)])...))

### while ###
exports.while_ = macro(null, 'while_', (label, test, body...) ->
  if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
  block(label, [if_(not_(test), break_(label))].concat(body).concat([continue_(label)])...))

### until ###
exports.until_ = macro(null, 'until_', (label,body..., test) ->
   if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
   body = body.concat([if_(not_(test), continue_(label))])
   block(label, body...))

### aka. lisp style catch/throw  ###
exports.catch_ = special(-1, 'catch_', (solver, cont, tag, forms...) ->
  tagCont = (v, solver) ->
    solver.pushCatch(v, cont)
    formsCont = solver.expsCont(forms, (v2, solver) -> solver.popCatch(v); [cont, v2, solver])
    [formsCont, v, solver]
  solver.cont(tag, tagCont))

### aka lisp style throw ###
exports.throw_ = special(2, 'throw_', (solver, cont, tag, form) ->
  formCont =  (v, solver) ->
    solver.cont(form, (v2, solver) ->
      solver.protect(solver.findCatch(v))(v2, solver))(v, solver)
  solver.cont(tag, formCont))

### aka. lisp's unwind-protect ###
exports.protect = special(-1, 'protect', (solver, cont, form, cleanup...) ->
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

# todo: need a trampoline for running the current continuation until done or faildone

### used by callcc and callfc ###
runner = (solver, cont) -> (v) ->
  while not solver.done then [cont, v, solver] = cont(v, solver)
  solver.done = false
  return v

### callfc(someFunction(kont) -> body)
current continuation @cont can be captured in someFunction
###
exports.callcc = special(1, 'callcc', (solver, cont, fun) -> (v, solver) ->
  cont(fun(runner(solver.clone(), cont)), solver))

### callfc(someFunction(fc) -> body)
current solver.failcont can be captured in someFunction
###
exports.callfc = special(1, 'callfc', (solver, cont, fun) -> (v, solver) ->
  cont(fun(runner(solver.clone(), solver.failcont)), solver))

### callcs(someFunction(solver, kont) -> body)
  the solver and current cont can be captured in someFunction
  ###
exports.callcs = special(1, 'callcs', (solver, cont, fun) -> (v, solver) ->
  cont(fun(solver.clone(), cont), solver))

### lisp style quasiquote/unquote/unquote-slice "`", "," and ",@" ###
exports.quasiquote = exports.qq = special(1, 'quasiquote', (solver, cont, item) ->
  solver.quasiquote?(item, cont))

exports.unquote = exports.uq = special(1, 'unquote', (solver, cont, item) ->
  throw "unquote: too many unquote and unquoteSlice" )

exports.unquoteSlice = exports.uqs = special(1, 'unquoteSlice', (solver, cont, item) ->
  throw "unquoteSlice: too many unquote and unquoteSlice")