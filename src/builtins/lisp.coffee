solve = require "../../src/solve"

special = solve.special
macro = solve.macro

exports.quote = special((solver, cont, exp) ->
    (v, solver) -> cont(exp, solver))

exports.eval_ = special((solver, cont, exp) ->
  solver.cont(exp, (v, solver) -> solver.cont(v, cont)(null, solver)))

exports.begin = special((solver, cont, exps...) -> solver.expsCont(exps, cont))

if_fun = (solver, cont, test, then_, else_) ->
  then_cont = solver.cont(then_, cont)
  else_cont = solver.cont(else_, cont)
  solver.cont(test, (v, solver) ->
    if (v) then then_cont(v, solver)
    else else_cont(v, solver))

exports.if_ = special(if_fun)

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
      if (v) then then_cont(v, solver)
      else iff_else_cont(v, solver))

exports.iff = special(iff_fun)

### iff's macro version
iff = macro (clauses_, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    exports.if_(clauses[0][0], clauses[0][1], else_)
  else
     exports.if_(clauses[0][0], clauses[0][1], iff(clauses[1...], else_)
###

exports.block = block = special((solver, cont, label, body) ->
  solver.exits[label] = cont
  solver.continues[label] = fun = solver.cont(body, cont)
  fun)

exports.break_ = break_ = special((solver, cont, label=null, value=null) ->
  solver.cont(value, (v, solver) ->
    solver.protects(null, solver)
    slover.exits[label](v, solver)))

exports.continue_ = continue_ = special((solver, cont, label=null) ->
  (v, solver) ->
    solver.protects(null, solver)
    slover.continues[label](v, solver))

exports.loop = macro((label, body) ->
  block(label, body.concat([continue_(label)])...))

exports.while_ = macro((label, test, body) ->
  block(label, ([if_(not_(test), break_(label))].concat(body).concat([continue_(label)]))))

exports.until = macro((label, body, test) ->
   body = body.concat([exports.if_(exports.not_(test), exports.continue_(label))])
   exports.block(label, body...))

exports.catch_ = special((solver, cont, tag, forms...) ->
  solver.cont(tag, (v, solver) ->
    solver.pushCatch(v, (v, solver) -> cont(v, solver))
    solver.exps_cont(forms, cont)(v, solver)))

exports.throw_ = special((solver, cont, tag, form) ->
  solver.cont(tag, (v, solver) ->
    solver.cont(form, (v2, solver) ->
      solver.protects(null)
      solver.findCatch(v)(v2))))

exports.unwindprotect = special((solver, cont, form, cleanup...) ->
  oldprotect = solver.protect
  cleanupProtect = solver.expsCont(cleanup, oldprotect)
  compiler.protect = (v, solver) -> cleanupProtect(v, solver)
  cleanupCont = (v1, solver) -> solver.expsCont(cleanup, (v2, solver) -> cont(v1, solver))
  result = solver.cont(form, cleanupCont)
  solver.protect = oldprotect
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