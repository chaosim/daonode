solve = require "../../src/solve"
solver = solve.solver

special = solve.special
macro = solve.macro
Trail = solve.Trail

exports.succeed = special('succeed', (cont) -> cont)()

exports.fail = special('fail', (cont) -> -> solver.failcont())()

exports.andp = special('andp', (cont, args...) -> solver.expsCont(args, cont))

exports.cutable = special('cutable', (cont, x) -> ->
  cc = solver.cutCont
  solver.cont(x, -> solver.cutCont = cc; cont())(null))

exports.cut = special('cut', (cont) -> ->
  solver.failcont = solver.cutCont
  cont())()

exports.ifp = special('ifp', (cont, test, action, else_) ->
  #if -> Then; _Else :- If, !, Then.
  #If -> _Then; Else :- !, Else.
  #If -> Then :- If, !, Then.
  ->
    # at first: make ifp cutable
    cc = solver.cutCont
    newCont = -> solver.cutCont = cc; cont()
    actionCont = solver.cont(action, newCont)
    elseCont =  solver.cont(else_, newCont)
    if else_
      trail = new Trail
      state = solver.state
      fc = solver.failcont
      fc2 = -> solver.failcont = fc2; fc()
      solver.failcont = ->
        trail.undo()
        solver.state = state
        solver.failcont = fc2
        elseCont()
    solver.cont(test, ->
      # add cut after test, try test only once
      solver.failcont = solver.cutCont
      actionCont()))

exports.orp = special('orp', (cont, x, y) ->
  xcont = solver.cont(x, cont)
  ycont = solver.cont(y, cont)
  ->
    trail = new Trail
    state = solver.state
    fc = solver.failcont
    solver.failcont = ->
      trail.undo()
      solver.state = state
      solver.failcont = fc
      ycont
    solver.trail = trail
    xcont)

orp_fun = (cont, args...) ->
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
    ycont = orp_fun(cont, y...)
  return do (xcont=xcont, ycont=ycont) -> ->
    trail = new Trail
    state = solver.state
    fc = solver.failcont
    solver.failcont = ->
      trail.undo()
      solver.state = state
      solver.failcont = fc
      ycont
    solver.trail = trail
    xcont

exports.orp = special('orp', orp_fun)

exports.notp = special('notp', (cont, x) -> (v) ->
  trail = solver.trail
  solver.trail = new Trail
  fc = solver.failcont
  state = solver.state
  solver.failcont = (v) ->
    solver.trail.undo()
    solver.trail = trail
    solver.state = state
    solver.failcont = fc
    [cont, v]
  solver.cont(x, (v) ->
    solver.failcont = fc
    [fc, v])(v))

exports.repeat = special('repeat', (cont) ->
  (v) -> solver.failcont = cont; [cont, null])()

# todo call(goal)

exports.call = special('call', (cont, args...) ->
  solver.argsCont(args, (params,  solver) ->
    goal = params[0]
    solver.cont(goal.caller.callable(goal.args.concat(params[1...])...), cont)(null)))

exports.findall = special('findall', (cont, exp) ->
  findallcont = solver.cont(exp, (v) -> [solver.failcont, v])
  (v) ->
    fc = solver.failcont
    solver.failcont =  (v) -> solver.failcont = fc; [cont, v]
    [findallcont, v])

exports.xfindall = special('findall', (cont, exp) ->
  findallcont = solver.cont(exp,solver.failcont)
  (v) ->
    fc = solver.failcont
    solver.failcont =  (v) -> solver.failcont = fc; [cont, v]
    [findallcont, v])

exports.once = special('once', (cont, x) -> (v) ->
  fc = solver.failcont
  [solver.cont(x, (v) -> solver.failcont = fc; [cont, v]), null])

exports.is_ = special('is_', (cont, vari, exp) ->
  # different from assign in lisp.coffee:
  # by using vari.bind, this is saved in solver.trail and can be restored in solver.failcont
  solver.cont(exp, (v) ->  vari.bind(v, solver.trail); [cont, true]))

#todo unify function as the third function
exports.unifyFun = unifyFun = (cont, x, y) -> (v) ->
  if solver.trail.unify(x, y) then cont(true)
  else solver.failcont(false)

exports.unify = special('unify', unifyFun)

exports.notunifyFun = notunifyFun = (cont, x, y) -> (v) ->
  if not solver.trail.unify(x, y) then cont(true)
  else solver.failcont(false)

exports.notunify = special('notunify', notunifyFun)

exports.unifyListFun = unifyListFun = (cont, xs, ys) ->  (v) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false)
  else for i in [0...xlen]
    if not solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false)
  cont(true)

exports.unifyList = unifyList = special('unifyList', unifyListFun)

exports.notunifyListFun = notunifyListFun = (cont, xs, ys) ->  (v) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false)
  else for i in [0...xlen]
    if solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false)
  cont(true)

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
exports.callfc = special('callfc', (cont, fun) -> (v) ->
                         result = fun(solver.failcont)[1]
                         solver.done = false
                         cont(result))

exports.truep = special('truep', (cont, fun, x) -> solver.cont(x, (x1) ->
  if x1 then cont(x1)
  else solver.failcont(x1)))

exports.falsep = special('falsep', (cont, fun, x) -> solver.cont(x, (x1) ->
  if not x1 then cont(x1)
  else solver.failcont(x1)))

exports.unaryPredicate = unaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (cont, x) -> solver.cont(x, (x1) ->
      result = fun(x1)
      if result then cont(result)
      else solver.failcont(result)))

exports.binaryPredicate = binaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (cont, x, y) ->
    solver.cont(x, (x1) -> solver.cont(y,  (y1) ->
      result = fun(x1, y1)
      if result then cont(result)
      else solver.failcont(result))))

exports.eqp = binaryPredicate((x, y) -> x is y)
exports.nep = binaryPredicate((x, y) -> x isnt y)
exports.ltp = binaryPredicate((x, y) -> x < y)
exports.lep = binaryPredicate((x, y) -> x <= y)
exports.gtp = binaryPredicate((x, y) -> x > y)
exports.gep = binaryPredicate((x, y) -> x >= y)

exports.ternaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (cont, x, y, z) ->
    solver.cont(x, (x1) -> solver.cont(y,  (y1) -> solver.cont(z,  (z1) ->
      result = fun(x1, y1, z1)
      if result then cont(result)
      else solver.failcont(result)))))

exports.functionPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(name, (cont, args...) ->
    solver.argsCont(args, (params) ->
      result = fun(params...)
      if result then cont(result)
      else solver.failcont(result)))

exports.between = special('between', (cont, fun, x, y, z) ->
  # like "between" in prolog, but should be that y is between [x, z]
  # after evaluated, is y between x and z if y is not Var? or else try all number between z and z
    solver.cont(x, (x1) -> solver.cont(y,  (y1) -> solver.cont(z,  (z1) ->
      if x1 instanceof dao.Var then throw dao.TypeError(x)
      else if y1 instanceof dao.Var then throw new dao.TypeError(y1)
      if y1 instanceof dao.Var
        y11 = y1
        fc = solver.failcont
        solver.failcont = (v) ->
          y11++
          if y11>z1 then fc(v)
          else y1.bind(y11, solver.trail); cont(y11)
        y1.bind(y11, solver.trail); cont(y11)
      else
        result = (x1<=y1<=z1)
        if result then cont(true)
        else solver.failcont(false)))))

exports.rangep = special('between', (cont, fun, x, y) ->
  # select all of values between x and y as choices
  solver.cont(x, (x1) -> solver.cont(y,  (y1) ->
    if x1 instanceof dao.Var then throw dao.TypeError(x)
    else if y1 instanceof dao.Var then throw new dao.TypeError(y)
    else if x1>y1 then return solver.failcont(false)
    result = x1
    fc = solver.failcont
    solver.failcont = (v) ->
      result++
      if result>y1 then fc(v)
      else cont(result)
    cont(result))))

exports.varp = special('varp', (cont, x) ->
  solver.cont(x, (x1) ->
    if (x1 instanceof dao.Var) then cont(true)
    else solver.failcont(false)))

exports.nonvarp = special('varp', (cont, x) ->
  solver.cont(x, (x1) ->
    if (x1 not instanceof dao.Var) then cont(true)
    else solver.failcont(false)))

exports.numberp = special('numberp', (cont, x) ->
  solver.cont(x, (x1) ->
    if _.isNumber(x1) then cont(true)
    else solver.failcont(false)))

exports.stringp = special('stringp', (cont, x) ->
  solver.cont(x, (x1) ->
    if _.isString(x1) then cont(true)
    else solver.failcont(false)))

exports.atomp = special('atomp', (cont, x) ->
  solver.cont(x, (x1) ->
    if _.isNumber(x1) or _.isString(x1) then cont(true)
    else solver.failcont(false)))

exports.arrayp = special('arrayp', (cont, x) ->
  solver.cont(x, (x1) ->
    if _.isArray(x1) then cont(true)
    else solver.failcont(false)))

exports.callablep = special('callablep', (cont, x) ->
  solver.cont(x, (x1) ->
    if x1 instanceof dao.Apply then cont(true)
    else solver.failcont(false)))
