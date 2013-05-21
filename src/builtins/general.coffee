solve = require "../../src/solve"
fun = solve.fun
special = solve.special

exports.print_ = fun('print_', (args...) -> console.log(args...))
exports.add = fun('add', (x, y) -> x+y)
exports.sub = fun('sub', (x, y) -> x-y)
exports.mul = fun('mul', (x, y) -> x*y)
exports.div = fun('div', (x, y) -> x/y)
exports.mod = fun('mod', (x, y) -> x%y)

exports.and_ = fun('and_', (x, y) -> x and y)
exports.or_ = fun('or_', (x, y) -> x or y)
exports.not_ = fun('not_', (x) -> not x)
exports.lshift = fun('lshift', (x, y) -> x<<y)
exports.rshift = fun('rshift', (x, y) -> x>>y)
exports.bitand = fun('bitand', (x, y) -> x&y)
exports.bitor = fun('bitor', (x, y) -> x|y)
exports.bitnot = fun('bitnot', (x) -> ~x)

#exports.eq = fun('eq', (x, y) -> x==y)
#exports.ne = fun('ne', (x, y) -> x!=y)
#exports.lt = fun('lt', (x, y) -> x<y)
#exports.le = fun('le', (x, y) -> x<=y)
#exports.ge = fun('ge', (x, y) -> x>=y)
#exports.gt = fun('gt', (x, y) -> x>y)

# more optimized version
exports.eq = special('eq', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x==v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.ne = special('ne', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x!=v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.lt = special('lt', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x<=v, solver))
  xcont = (v, solver) ->  (x = v; ycont(null, solver))
  solver.cont(x, xcont))

exports.le = special('le', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x<=v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.gt = special('gt', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x>v, solver))
  xcont = (v, solver) ->  (x = v; ycont(null, solver))
  solver.cont(x, xcont))

exports.ge = special('ge', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x>=v, solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

# Because not using vari.bind, these are not saved in solver.trail and so it can NOT be restored in solver.failcont
# EXCEPT the vari has been in solver.trail in the logic branch before.
exports.inc = special('inc', (solver, cont, vari) ->
  (v, solver) -> cont(++vari.binding, solver))

exports.inc2 = special('inc2', (solver, cont, vari) ->
  (v, solver) -> (vari.binding++; cont(++vari.binding, solver)))

exports.dec = special('dec', (solver, cont, vari) ->
  (v, solver) -> (cont(--vari.binding, solver)))

exports.dec2 = special('dec2', (solver, cont, vari) ->
  (v, solver) -> (vari.binding--; cont(--vari.binding, solver)))

exports.getvalue = special('getvalue', (solver, cont, x) ->
  (v, solver) -> cont(solver.trail.getvalue(x), solver))

exports.length = special('length', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v.length, solver)))

exports.neg = special('neg', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(-v, solver)))

exports.abs = special('abs', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(Math.abs(v), solver)))

exports.index = special('index', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x[y], solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.first = special('first', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[0], solver)))

exports.left = special('first', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[1...], solver)))

exports.second = special('first', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[1], solver)))

exports.third = special('first', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v[2], solver)))

exports.concat = special('concat', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x.concat(y), solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.list = special('list', (solver, cont, args...) ->
  solver.argsCont(args, cont))

exports.push = special('push', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x.push(y), solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.free = special('freep', (solver, cont, x) ->
  # x is a free variable?
  # this never fail, which is different from logic.freep
  (v, solver) -> cont(solver.trail.deref(x) instanceof Var, solver))
