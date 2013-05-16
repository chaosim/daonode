_ = require('underscore')
solve = require "../../src/solve"
general = require "../../src/builtins/general"

special = solve.special
macro = solve.macro
debug = solve.debug

exports.quote = special('quote', (solver, cont, exp) ->
    (v, solver) -> [cont, exp, solver])

exports.eval_ = special('eval', (solver, cont, exp) ->
  solver.cont(exp, (v, solver) -> [solver.cont(v, cont), null, solver]))

exports.assign = special('assign', (solver, cont, vari, exp) ->
  solver.cont(exp, (v, solver) -> (vari.binding = v; [cont, v, solver])))

exports.begin = special('begin', (solver, cont, exps...) -> solver.expsCont(exps, cont))

if_fun = (solver, cont, test, then_, else_) ->
  then_cont = solver.cont(then_, cont)
  else_cont = solver.cont(else_, cont)
  solver.cont(test, (v, solver) ->
    if (v) then [then_cont, v, solver]
    else [else_cont, v, solver])

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
#  debug 'enter block:', label, exits
#  debug 'default exits:',defaultExits
  holder = [null]
  continues = solver.continues[label] ?= []
  continues.push(holder)
  defaultContinues = solver.continues[''] ?= []   # if no label, go here
  defaultContinues.push(holder)
#  debug 'body:', body
  holder[0] = fun = solver.expsCont(body, cont)
#  debug 'leave block, holder:', holder
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
#  debug label, exits
  if not exits or exits==[] then throw Error(label)
  exitCont = exits[exits.length-1]
  solver.cont(value, (v, solver) ->
    [solver.protect(exitCont), v, solver]))

exports.continue_ = continue_ = special('continue_', (solver, cont, label='') ->
  continues = solver.continues[label]
#  debug 'continue', continues
#  debug label, exits
  if not continues or continues==[] then throw Error(label)
  continueCont = continues[continues.length-1]
  (v, solver) ->
    [solver.protect(continueCont[0]), v, solver])

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
#  debug('enter protect', solver.protect, form, 'cleanup...:', cleanup)
  oldprotect = solver.protect
  solver.protect = (fun) -> (v1, solver) ->
                               solver.expsCont(cleanup, (v2, solver) ->
                                 solver.protect = oldprotect;
                                 [oldprotect(fun), v1, solver])(v1, solver)
#  debug('protect:', solver.protect)
#  debug 'before cleanup'
  cleanupCont = (v1, solver) ->
#    debug 'cleanup', v1
    solver.expsCont(cleanup, (v2, solver) ->
#                    debug 'cont', v2
                    solver.protect = oldprotect
                    cont(v1, solver))(v1, solver)
#  debug 'exits', solver.exits
  result = solver.cont(form, cleanupCont)
  result)

###
exports.calcc = special((solver, cont, fun) ->
  body = fun.body.subst(dict(fun.params[0], LamdaVar(fun.params[0].name)))
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  params = (x.interlang() for x in fun.params)
  function1 = il.Lamda([k]+params, body.cps(compiler, k))
  k1 = compiler.new_var(new il.ConstLocalVar('cont'))
  v = compiler.new_var(new il.ConstLocalVar('v'))
  function1(cont, il.Lamda([k1, v], cont(v)))

  quasiquote_args: (args) ->
    if not args then pyield []
    else if args.length is 1
      for x in @quasiquote(args[0])
        try pyield x.unquote_splice
        catch e then pyield [x]
    else
      for x in @quasiquote(args[0])
        for y in @quasiquote_args(args[1..])
          try x = x.unquote_splice
          catch e then x = [x]
          pyield x+y

  #@special
  callfc = (compiler, cont, fun) ->
    Todo_callfc_need_tests
    fun(il.failcont)

  ###