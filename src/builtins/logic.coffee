solve = require "../../src/solve"

special = solve.special
Trail = solve.Trail

exports.succeed = special((solver, cont) -> (v, solver) -> cont(true, solver))()

exports.fail = special((solver, cont) -> (v, solver) -> solver.failcont(false, solver))()

exports.andp = special((solver, cont, x, y) -> solver.cont(x, solver.cont(y, cont)))

exports.ifp = special((solver, cont, test, action) -> solver.cont(test, solver.cont(action, cont)))

exports.cutable = special((solver, cont, x) -> (v, solver) ->
  cc = solver.cutCont
  solver.cont(x, (v, solver) -> solver.cutCont = cc; cont(v, solver))(exports.NULL, solver))

exports.orp = special((solver, cont, x, y) -> (v, solver) ->
  trail = new Trail
  state = solver.state
  fc = solver.failcont
  xcont = solver.cont(x, cont)
  ycont = solver.cont(y, cont)
  solver.failcont = (v, solver) ->
    trail.undo()
    solver.state = state
    solver.failcont = fc
    ycont(v, solver)
  solver.trail = trail
  xcont(null, solver))

exports.once = special((solver, cont, x) -> (v, solver) ->
  fc = solver.failcont
  solver.cont(x, (v, solver) -> solver.failcont = fc; cont(v, solver))(exports.NULL, solver))

exports.notp = special((solver, cont, x) -> (v, solver) ->
  trail = solver.trail
  solver.trail = new Trail
  fc = solver.failcont
  state = solver.state
  solver.failcont = (v, solver) ->
    solver.trail.undo()
    solver.trail = trail
    solver.state = state
    solver.failcont = fc
    cont(v, solver)
  solver.cont(x, (v, solver) ->
    solver.failcont = fc
    fc(v, solver))(v, solver))

exports.cut = special((solver, cont) -> (v, solver) ->
  solver.failcont = solver.cutCont
  cont(v, solver))()

exports.repeat = special((solver, cont) ->
  (v, solver) -> solver.failcont = cont; cont(null, solver))()

exports.findall = special((solver, cont, exp) ->
  (v, solver) ->
    fc = solver.failcont
    solver.failcont =  (v, solver) -> solver.failcont = fc; cont(v, solver)
    solver.cont(exp, (v, solver) -> solver.failcont(v, solver))(v, solver))

exports.unify = special((solver, cont, x, y) -> (v, solver) ->
  if solver.trail.unify(x, y) then cont(true, solver)
  else solver.failcont(false, solver))

exports.is_ = special((solver, cont, vari, exp) ->
   solver.cont(exp, (v, solver) ->  vari.bind(v, solver.trail); cont(true, solver)))
