# #### lisp builtins
# lispt.coffee doesn't know trail, failcont, state and the like.
# lisp knows cont only.

_ = require('underscore')
core = require "../core"
general = require "./general"

special = core.special
macro = core.macro

debug = core.debug

# aka lisp's quote, like in lisp, 'x==x, quote(x) === x 
exports.quote = special(1, 'quote', (solver, cont, exp) ->
    cont(exp))

# aka lisp's eval, solve(eval_(quote(x))) means solve(x),  
exports.eval_ = special(1, 'eval', (solver, cont, exp) ->
  solver.solve(exp, (v) -> solver.solve(v, cont)))

# vari.binding = exp
exports.assign = special(2, 'assign', (solver, cont, vari, exp) ->
  # different from is_ in logic.coffee: <br/>
  # Because not using vari.bind, this is not saved in solver.trail  <br/>
  # and so it can NOT be restored in solver.failcont <br/>
  # EXCEPT the vari has been in solver.trail in the logic branch before.

  solver.solve(exp, (v) ->
    if v instanceof core.Var
      new core.TypeError(v, "do NOT assign free logic var to var")
    vari.binding = v;
    cont(v)))

# vari.binding = 0 <br/>
#  provide this for reducing continuation, and make code running faster.
exports.zero = special(1, 'zero', (solver, cont, vari, exp) ->
  (v) -> (vari.binding = 0; cont(v)))

# vari.binding = 1 <br/>
#  provide this for reducing continuation, and make code running faster.
exports.one = special(1, 'one', (solver, cont, vari, exp) ->
 (v) -> (vari.binding = 1; cont(v)))

# aka lisp's begin, same as logic.andp 
exports.begin = special(null, 'begin', (solver, cont, exps...) -> solver.solveExps(exps, cont))

if_fun = (solver, cont, test, then_, else_) ->
  solver.solve(test,  (v) ->
    if (v) then solver.solve(then_, cont)
    else solver.solve(else_, cont))

# lisp style if. <br/>
#  different from logic.ifp, when test fail, it do not run else_ clause.
exports.if_ = if_ = special([2,3], 'if_', if_fun)

iff_fun = (solver, cont, clauses, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    [test, then_] = clauses[0]
    if_fun(solver, cont, test, then_, else_)
  else
    [test, then_] = clauses[0]
    action = (v) ->
      if (v) then solver.solve(then_, cont)
      else iff_fun(solver, cont, clauses[1...], else_)
    solver.solve(test, action)


#iff [ [test1, body1], <br/>
#      [test2, body2]  <br/>
#    ] <br/>
#    else_

exports.iff = special(-2, 'iff', iff_fun)

# lisp style block 
exports.block = block = special(null, 'block', (solver, cont, label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat(body))
  fun = (v) ->
    exits = solver.exits[label] ?= []
    exits.push(cont)
    defaultExits = solver.exits[''] ?= []  # if no label, go here
    defaultExits.push(cont)
    holder = [null]
    continues = solver.continues[label] ?= []
    continues.push(holder)
    defaultContinues = solver.continues[''] ?= []   # if no label, go here
    defaultContinues.push(holder)
    holder[0] = fun
    result = solver.solveExps(body, cont)
    exits.pop()
    if exits.length is 0 then delete solver.exits[label]
    continues.pop()
    if continues.length is 0 then delete solver.continues[label]
    defaultExits.pop()
    defaultContinues.pop()
    result
  fun(null))

# break a block 
exports.break_ = break_ = special([0, 1,2], 'break_', (solver, cont, label='', value=null) ->
  if value != null and not _.isString label then throw new TypeError([label, value])
  if value is null and not _.isString label then (value = label; label = '')
  exits = solver.exits[label]
  if not exits or exits==[] then throw new  Error(label)
  exitCont = exits[exits.length-1]
  solver.solve(value, solver.protect(exitCont)))

# continue a block 
exports.continue_ = continue_ = special([0,1], 'continue_', (solver, cont, label='') ->
  continues = solver.continues[label]
  if not continues or continues==[] then throw new  Error(label)
  continueCont = continues[continues.length-1]
  solver.protect(continueCont[0])(null))

not_ = general.not_

# loop 
exports.loop_ = macro(null, 'loop', (label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat body)
  block(label, body.concat([continue_(label)])...))

# while 
exports.while_ = macro(null, 'while_', (label, test, body...) ->
  if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
  block(label, [if_(not_(test), break_(label))].concat(body).concat([continue_(label)])...))

# until 
exports.until_ = macro(null, 'until_', (label,body..., test) ->
   if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
   body = body.concat([if_(not_(test), continue_(label))])
   block(label, body...))

# aka. lisp style catch/throw  
exports.catch_ = special(-1, 'catch_', (solver, cont, tag, forms...) ->
  solver.solve(tag,  (v) ->
    solver.pushCatch(v, cont)
    solver.solveExps(forms, (v2) -> solver.popCatch(v); cont(v2))))


# aka lisp style throw 
exports.throw_ = special(2, 'throw_', (solver, cont, tag, form) ->
  solver.solve(tag,  (v) ->
    solver.solve(form, (v2) ->
      solver.protect(solver.findCatch(v))(v2))))

# aka. lisp's unwind-protect 
exports.protect = special(-1, 'protect', (solver, cont, form, cleanup...) ->
  oldprotect = solver.protect
  solver.protect = (fun) -> (v1) ->
                               solver.solveExps(cleanup, (v2) ->
                                 solver.protect = oldprotect;
                                 oldprotect(fun)(v1))
  solver.solve(form, (v1) ->
    solver.solveExps(cleanup, (v2) ->
      solver.protect = oldprotect
      cont(v1))))


# callcc(someFunction(kont) -> body) <br/>
#current continuation @cont can be captured in someFunction
exports.callcc = special(1, 'callcc', (solver, cont, fun) -> (v) ->
  faked = solver.fake()
  cc = (v) ->
    solver.restore(faked)
    result = solver.run(v, cont)
    solver.finished = false
    solver.trail.getvalue(result[1])
  cont(fun(cc)))

# callfc(someFunction(fc) -> body) <br/>
#current solver.failcont can be captured in someFunction
exports.callfc = special(1, 'callfc', (solver, cont, fun) -> (v) ->
  faked = solver.fake()
  fc = (v) ->
    solver.restore(faked)
    result = solver.run(v,  solver.failcont)
    solver.finished = false
    solver.trail.getvalue(result[1])
  cont(fun(fc)))

# 0.1.11 update
# callcs(someFunction(solver, faked, kont) -> body) <br/>
#  the solver, solver's current content and current cont can be captured in someFunction
exports.callcs = special(1, 'callcs', (solver, cont, fun) -> (v) ->
  cont(fun(solver, solver.fake(), cont)))

# lisp style quasiquote/unquote/unquote-slice "`", "," and ",@" 
exports.quasiquote = exports.qq = special(1, 'quasiquote', (solver, cont, item) ->
  solver.quasiquote?(item, cont))

exports.unquote = exports.uq = special(1, 'unquote', (solver, cont, item) ->
  throw new Error "unquote: too many unquote and unquoteSlice" )

exports.unquoteSlice = exports.uqs = special(1, 'unquoteSlice', (solver, cont, item) ->
  throw new Error "unquoteSlice: too many unquote and unquoteSlice")
