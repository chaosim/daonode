solve = require "../../src/solve"

special = solve.special
macro = solve.macro
Trail = solve.Trail

exports.succeed = special('succeed', (solver, cont) -> cont)()

exports.fail = special('fail', (solver, cont) -> (v, solver) -> solver.failcont(v, solver))()

exports.andp = special('andp', (solver, cont, args...) -> solver.expsCont(args, cont))

exports.cutable = special('cutable', (solver, cont, x) -> (v, solver) ->
  cc = solver.cutCont
  solver.cont(x, (v, solver) -> solver.cutCont = cc; [cont, v, solver])(null, solver))

exports.cut = special('cut', (solver, cont) -> (v, solver) ->
  solver.failcont = solver.cutCont
  cont(v, solver))()

exports.ifp = special('ifp', (solver, cont, test, action, else_) ->
  #if -> Then; _Else :- If, !, Then.
  #If -> _Then; Else :- !, Else.
  #If -> Then :- If, !, Then.
  (v, solver) ->
    # at first: make ifp cutable
    cc = solver.cutCont
    newCont = (v, solver) -> solver.cutCont = cc; cont(v, solver)
    actionCont = solver.cont(action, newCont)
    elseCont =  solver.cont(else_, newCont)
    if else_?
      trail = new Trail
      state = solver.state
      fc = solver.failcont
      fc2 = (v, solver) -> solver.failcont = fc2; fc(v, solver)
      solver.failcont = (v, solver) ->
        trail.undo()
        solver.state = state
        solver.failcont = fc2
        elseCont(v, solver)
    solver.cont(test, (v, solver) ->
      # add cut after test, try test only once
      solver.failcont = solver.cutCont
      actionCont(v, solver)))

exports.orp = special('orp', (solver, cont, x, y) ->
  xcont = solver.cont(x, cont)
  ycont = solver.cont(y, cont)
  (v, solver) ->
    trail = new Trail
    state = solver.state
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      trail.undo()
      solver.state = state
      solver.failcont = fc
      [ycont, v, solver]
    solver.trail = trail
    [xcont, null, solver])

orp_fun = (solver, cont, args...) ->
  length = args.length
  if length is 0 then throw new ArgumentError(args)
  else if length is 1 then return solver.cont(args[0], cont)
  else if length is 2
    x = args[0]
    y = args[1]
    xcont = solver.cont(x, cont)
    ycont = solver.cont(y, cont)
  else
    x = args[0]
    y = args[1...]
    xcont = solver.cont(x, cont)
    ycont = orp_fun(solver, cont, y...)
  return do (xcont=xcont, ycont=ycont) -> (v, solver) ->
    trail = new Trail
    state = solver.state
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      trail.undo()
      solver.state = state
      solver.failcont = fc
      [ycont, v, solver]
    solver.trail = trail
    [xcont, null, solver]

exports.orp = special('orp', orp_fun)

exports.notp = special('notp', (solver, cont, x) -> (v, solver) ->
  trail = solver.trail
  solver.trail = new Trail
  fc = solver.failcont
  state = solver.state
  solver.failcont = (v, solver) ->
    solver.trail.undo()
    solver.trail = trail
    solver.state = state
    solver.failcont = fc
    [cont, v, solver]
  solver.cont(x, (v, solver) ->
    solver.failcont = fc
    [fc, v, solver])(v, solver))

exports.repeat = special('repeat', (solver, cont) ->
  (v, solver) -> solver.failcont = cont; [cont, null, solver])()

# todo call(goal)

exports.call = special('call', (solver, cont, args...) ->
  solver.argsCont(args, (params,  solver) ->
    goal = params[0]
    solver.cont(goal.caller.callable(goal.args.concat(params[1...])...), cont)(null, solver)))

exports.findall = special('findall', (solver, cont, exp) ->
  findallcont = solver.cont(exp, (v, solver) -> [solver.failcont, v, solver])
  (v, solver) ->
    fc = solver.failcont
    solver.failcont =  (v, solver) -> solver.failcont = fc; [cont, v, solver]
    [findallcont, v, solver])

exports.xfindall = special('findall', (solver, cont, exp) ->
  findallcont = solver.cont(exp,solver.failcont)
  (v, solver) ->
    fc = solver.failcont
    solver.failcont =  (v, solver) -> solver.failcont = fc; [cont, v, solver]
    [findallcont, v, solver])

exports.once = special('once', (solver, cont, x) -> (v, solver) ->
  fc = solver.failcont
  [solver.cont(x, (v, solver) -> solver.failcont = fc; [cont, v, solver]), null, solver])

exports.is_ = special('is_', (solver, cont, vari, exp) ->
  # different from assign in lisp.coffee:
  # by using vari.bind, this is saved in solver.trail and can be restored in solver.failcont
  solver.cont(exp, (v, solver) ->  vari.bind(v, solver.trail); [cont, true, solver]))

#todo unify function as the third function
exports.unifyFun = unifyFun = (solver, cont, x, y) -> (v, solver) ->
  if solver.trail.unify(x, y) then cont(true, solver)
  else solver.failcont(false, solver)

exports.unify = special('unify', unifyFun)

exports.notunifyFun = notunifyFun = (solver, cont, x, y) -> (v, solver) ->
  if not solver.trail.unify(x, y) then cont(true, solver)
  else solver.failcont(false, solver)

exports.notunify = special('notunify', notunifyFun)

exports.unifyListFun = unifyListFun = (solver, cont, xs, ys) ->  (v, solver) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false, solver)
  else for i in [0...xlen]
    if not solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false, solver)
  cont(true, solver)

exports.unifyList = unifyList = special('unifyList', unifyListFun)

exports.notunifyListFun = notunifyListFun = (solver, cont, xs, ys) ->  (v, solver) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false, solver)
  else for i in [0...xlen]
    if solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false, solver)
  cont(true, solver)

exports.notunifyList = notunifyList = special('notunifyList', notunifyListFun)

#todo anothter version for many rules which should be more effecient by using arity and the signature.
# todo database rules: abolish, assert, retract
exports.rule = (name, fun) ->
  unless fun? then (fun = name; name = 'noname_rule')
  macro(name, (args...) ->
    clauses = fun(args...)
    clauses = for i in [0...clauses.length] by 2
      head = clauses[i]
      body = clauses[i+1]
      andp(unifyList(head, args), body)
    orp(clauses...))

# borrowed from lisp, same as in lisp.coffee
exports.callfc = special('callfc', (solver, cont, fun) -> (v, solver) ->
                         result = fun(solver.failcont)[1]
                         solver.done = false
                         cont(result, solver))

exports.truep = special('truep', (solver, cont, fun, x) -> solver.cont(x, (x1, solver) ->
  if x1 then cont(x1, solver)
  else solver.failcont(x1, solver)))

exports.falsep = special('falsep', (solver, cont, fun, x) -> solver.cont(x, (x1, solver) ->
  if not x1 then cont(x1, solver)
  else solver.failcont(x1, solver)))

exports.unaryPredicate = unaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (solver, cont, x) -> solver.cont(x, (x1, solver) ->
      result = fun(x1)
      if result then cont(result, solver)
      else solver.failcont(result, solver)))

exports.binaryPredicate = binaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (solver, cont, x, y) ->
    solver.cont(x, (x1, solver) -> solver.cont(y,  (y1, solver) ->
      result = fun(x1, y1)
      if result then cont(result, solver)
      else solver.failcont(result, solver))))

exports.eqp = binaryPredicate((x, y) -> x is y)
exports.nep = binaryPredicate((x, y) -> x isnt y)
exports.ltp = binaryPredicate((x, y) -> x < y)
exports.lep = binaryPredicate((x, y) -> x <= y)
exports.gtp = binaryPredicate((x, y) -> x > y)
exports.gep = binaryPredicate((x, y) -> x >= y)

exports.ternaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (solver, cont, x, y, z) ->
    solver.cont(x, (x1, solver) -> solver.cont(y,  (y1, solver) -> solver.cont(z,  (z1, solver) ->
      result = fun(x1, y1, z1)
      if result then cont(result, solver)
      else solver.failcont(result, solver)))))

exports.functionPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (solver, cont, args...) ->
    solver.argsCont(args, (params, solver) ->
      result = fun(params...)
      if result then cont(result, solver)
      else solver.failcont(result, solver)))

exports.between = special('between', (solver, cont, fun, x, y, z) ->
  # like "between" in prolog, but should be that y is between [x, z]
  # after evaluated, is y between x and z if y is not Var? or else try all number between z and z
    solver.cont(x, (x1, solver) -> solver.cont(y,  (y1, solver) -> solver.cont(z,  (z1, solver) ->
      if x1 instanceof dao.Var then throw dao.TypeError(x)
      else if y1 instanceof dao.Var then throw new dao.TypeError(y1)
      if y1 instanceof dao.Var
        y11 = y1
        fc = solver.failcont
        solver.failcont = (v, solver) ->
          y11++
          if y11>z1 then fc(v, solver)
          else y1.bind(y11, solver.trail); cont(y11, solver)
        y1.bind(y11, solver.trail); cont(y11, solver)
      else
        result = (x1<=y1<=z1)
        if result then cont(true, solver)
        else solver.failcont(false, solver)))))

exports.rangep = special('between', (solver, cont, fun, x, y) ->
  # select all of values between x and y as choices
  solver.cont(x, (x1, solver) -> solver.cont(y,  (y1, solver) ->
    if x1 instanceof dao.Var then throw dao.TypeError(x)
    else if y1 instanceof dao.Var then throw new dao.TypeError(y)
    else if x1>y1 then return solver.failcont(false, solver)
    result = x1
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      result++
      if result>y1 then fc(v, solver)
      else cont(result, solver)
    cont(result, solver))))

exports.varp = special('varp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if (x1 instanceof dao.Var) then cont(true, solver)
    else solver.failcont(false, solver)))

exports.nonvarp = special('varp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if (x1 not instanceof dao.Var) then cont(true, solver)
    else solver.failcont(false, solver)))

exports.numberp = special('numberp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if _.isNumber(x1) then cont(true, solver)
    else solver.failcont(false, solver)))

exports.stringp = special('stringp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if _.isString(x1) then cont(true, solver)
    else solver.failcont(false, solver)))

exports.atomp = special('atomp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if _.isNumber(x1) or _.isString(x1) then cont(true, solver)
    else solver.failcont(false, solver)))

exports.arrayp = special('arrayp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if _.isArray(x1) then cont(true, solver)
    else solver.failcont(false, solver)))

exports.callablep = special('callablep', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if x1 instanceof dao.Apply then cont(true, solver)
    else solver.failcont(false, solver)))
