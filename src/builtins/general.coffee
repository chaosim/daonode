solve = require "../../src/solve"
fun = solve.fun
special = solve.special

exports.print_ = special(null, 'eq', (solver, cont, args...) ->
  solver.argsCont(args, (args,  solver) -> console.log(args...); cont(null, solver)))

exports.eq = special(2, 'eq', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x==v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.ne = special(2, 'ne', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x!=v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.lt = special(2, 'lt', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x<=v, solver))
  xcont = (v, solver) ->  (x = v; ycont(null, solver))
  solver.cont(x, xcont))

exports.le = special(2, 'le', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x<=v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.gt = special(2, 'gt', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x>v, solver))
  xcont = (v, solver) ->  (x = v; ycont(null, solver))
  solver.cont(x, xcont))

exports.ge = special(2, 'ge', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x>=v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.add = special(2, 'add', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x+v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.sub = special(2, 'sub', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x-v, solver))
  xcont = (v, solver) ->  (x = v; ycont(null, solver))
  solver.cont(x, xcont))

exports.mul = special(2, 'mul', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x*v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.div = special(2, 'div', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x/v, solver))
  xcont = (v, solver) ->  (x = v; ycont(null, solver))
  solver.cont(x, xcont))

exports.mod = special(2, 'mod', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x%v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.and_ = special(2, 'and_', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x and v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.or_ = special(2, 'or_', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x and v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.not_ = special(1, 'not_', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(not v, solver)))

exports.lshift = special(2, 'lshift', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x << v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.rshift = special(2, 'rshift', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x >> v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.bitand = special(2, 'bitand', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x & v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.bitor = special(2, 'bitor', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x | v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.bitnot = special(1, 'not_', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(~v, solver)))

# Because not using vari.bind, these are not saved in solver.trail and so it can NOT be restored in solver.failcont
# EXCEPT the vari has been in solver.trail in the logic branch before.
exports.inc = special(1, 'inc', (solver, cont, vari) ->
  (v, solver) -> cont(++vari.binding, solver))

exports.inc2 = special(1, 'inc2', (solver, cont, vari) ->
  (v, solver) -> (vari.binding++; cont(++vari.binding, solver)))

exports.dec = special(1, 'dec', (solver, cont, vari) ->
  (v, solver) -> (cont(--vari.binding, solver)))

exports.dec2 = special(1, 'dec2', (solver, cont, vari) ->
  (v, solver) -> (vari.binding--; cont(--vari.binding, solver)))

exports.getvalue = special(1, 'getvalue', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(solver.trail.getvalue(v), solver)))

exports.length = special(1, 'length', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v.length, solver)))

exports.neg = special(1, 'neg', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(-v, solver)))

exports.abs = special(1, 'abs', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(Math.abs(v), solver)))

exports.index = special(2, 'index', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x[y], solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.first = special(1, 'first', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[0], solver)))

exports.left = special(1, 'left', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[1...], solver)))

exports.second = special(1, 'second', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[1], solver)))

exports.third = special(1, 'third', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[2], solver)))

exports.concat = special(2, 'concat', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x.concat(y), solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.list = special([], 'list', (solver, cont, args...) ->
  solver.argsCont(args, cont))

exports.push = special(2, 'push', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x.push(v), solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.free = special(1, 'freep', (solver, cont, x) ->
  # x is a free variable?
  # this never fail, which is different from logic.freep
  (v, solver) -> cont(solver.trail.deref(x) instanceof Var, solver))
