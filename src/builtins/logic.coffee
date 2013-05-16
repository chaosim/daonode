solve = require "../../src/solve"

special = solve.special
Trail = solve.Trail

exports.succeed = special('succeed', (solver, cont) -> cont)()

#exports.fail = special((solver, cont) -> (v, solver) -> [solver.failcont, false, solver])()
exports.fail = special('fail', (solver, cont) -> solver.failcont)()

exports.andp = special('andp', (solver, cont, x, y) -> solver.cont(x, solver.cont(y, cont)))

exports.ifp = special('ifp', (solver, cont, test, action) -> solver.cont(test, solver.cont(action, cont)))

exports.cutable = special('cutable', (solver, cont, x) -> (v, solver) ->
  cc = solver.cutCont
  solver.cont(x, (v, solver) -> solver.cutCont = cc; [cont, v, solver])(null, solver))

exports.cut = special('cut', (solver, cont) -> (v, solver) ->
  solver.failcont = solver.cutCont
  [cont, v, solver])()

exports.orp = special('orp', (solver, cont, x, y) -> (v, solver) ->
  trail = new Trail
  state = solver.state
  fc = solver.failcont
  xcont = solver.cont(x, cont)
  ycont = solver.cont(y, cont)
  solver.failcont = (v, solver) ->
    trail.undo()
    solver.state = state
    solver.failcont = fc
    [ycont, v, solver]
  solver.trail = trail
  [xcont, null, solver])

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

exports.unify = special('unify', (solver, cont, x, y) -> (v, solver) ->
  if solver.trail.unify(x, y) then [cont, true, solver]
  else [solver.failcont, false, solver])

exports.is_ = special('is_', (solver, cont, vari, exp) ->
   solver.cont(exp, (v, solver) ->  vari.bind(v, solver.trail); [cont, true, solver]))
