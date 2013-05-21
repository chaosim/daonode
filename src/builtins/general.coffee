solve = require "../../src/solve"
fun = solve.fun
special = solve.special

exports.print_ = fun(-1, 'print_', (args...) -> console.log(args...))
exports.add = fun(2, 'add', (x, y) -> x+y)
exports.sub = fun(2, 'sub', (x, y) -> x-y)
exports.mul = fun(2, 'mul', (x, y) -> x*y)
exports.div = fun(2, 'div', (x, y) -> x/y)
exports.mod = fun(2, 'mod', (x, y) -> x%y)

exports.and_ = fun(2, 'and_', (x, y) -> x and y)
exports.or_ = fun(2, 'or_', (x, y) -> x or y)
exports.not_ = fun(1, 'not_', (x) -> not x)
exports.lshift = fun(2, 'lshift', (x, y) -> x<<y)
exports.rshift = fun(2, 'rshift', (x, y) -> x>>y)
exports.bitand = fun(2, 'bitand', (x, y) -> x&y)
exports.bitor = fun(2, 'bitor', (x, y) -> x|y)
exports.bitnot = fun(2, 'bitnot', (x) -> ~x)

#exports.eq = fun('eq', (x, y) -> x==y)
#exports.ne = fun('ne', (x, y) -> x!=y)
#exports.lt = fun('lt', (x, y) -> x<y)
#exports.le = fun('le', (x, y) -> x<=y)
#exports.ge = fun('ge', (x, y) -> x>=y)
#exports.gt = fun('gt', (x, y) -> x>y)

# more optimized version
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

exports.list = special(-1, 'list', (solver, cont, args...) ->
  solver.argsCont(args, cont))

exports.push = special(2, 'push', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v, solver) -> cont(x.push(y), solver))
  xcont = (v, solver) ->  x = v; ycont(null, solver)
  solver.cont(x, xcont))

exports.free = special(1, 'freep', (solver, cont, x) ->
  # x is a free variable?
  # this never fail, which is different from logic.freep
  (v, solver) -> cont(solver.trail.deref(x) instanceof Var, solver))
