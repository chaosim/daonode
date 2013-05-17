solve = require "../../src/solve"

special = solve.special
macro = solve.macro
Trail = solve.Trail

exports.succeed = special('succeed', (solver, cont) -> cont)()

#exports.fail = special((solver, cont) -> (v, solver) -> [solver.failcont, false, solver])()
exports.fail = special('fail', (solver, cont) -> (v, solver) -> [solver.failcont, v, solver])()

exports.andp = special('andp', (solver, cont, args...) -> solver.expsCont(args, cont))

exports.ifp = special('ifp', (solver, cont, test, action) -> solver.cont(test, solver.cont(action, cont)))

exports.cutable = special('cutable', (solver, cont, x) -> (v, solver) ->
  cc = solver.cutCont
  solver.cont(x, (v, solver) -> solver.cutCont = cc; [cont, v, solver])(null, solver))

exports.cut = special('cut', (solver, cont) -> (v, solver) ->
  solver.failcont = solver.cutCont
  [cont, v, solver])()

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

exports.unifyFun = unifyFun = (solver, cont, x, y) -> (v, solver) ->
  if solver.trail.unify(x, y) then [cont, true, solver]
  else [solver.failcont, false, solver]

exports.unify = special('unify', unifyFun)

exports.is_ = special('is_', (solver, cont, vari, exp) ->
   solver.cont(exp, (v, solver) ->  vari.bind(v, solver.trail); [cont, true, solver]))

exports.unifyListFun = unifyListFun = (solver, cont, xs, ys) ->  (v, solver) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont
  else for i in [0...xlen]
    if not solver.trail.unify(xs[i], ys[i]) then return [solver.failcont, false, solver]
  [cont, true, solver]

exports.unifyList = unifyList = special('unify_list', unifyListFun)

exports.rule = (name, fun) ->
  unless fun? then (fun = name; name = 'noname_rule')
  macro(name, (args...) ->
    clauses = fun(args...)
    clauses = for i in [0...clauses.length] by 2
      head = clauses[i]
      body = clauses[i+1]
      andp(unifyList(head, args), body)
    orp(clauses...))