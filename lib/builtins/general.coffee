# #### general builtins

solve = require "../dao"
fun = solve.fun
special = solve.special

# console.log(arguments) 
exports.print_ = special(null, 'eq', (solver, cont, args...) ->
  solver.argsCont(args, (args,  solver) -> console.log(args...); cont(null)))

# x === y 
exports.eq = special(2, 'eq', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x==v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x !== y 
exports.ne = special(2, 'ne', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x!=v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x < y 
exports.lt = special(2, 'lt', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x<=v))
  xcont = (v) ->  (x = v; ycont(null))
  solver.cont(x, xcont))

# x <= y 
exports.le = special(2, 'le', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x<=v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

#  x > y 
exports.gt = special(2, 'gt', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x>v))
  xcont = (v) ->  (x = v; ycont(null))
  solver.cont(x, xcont))

# x >= y 
exports.ge = special(2, 'ge', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x>=v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x + y 
exports.add = special(2, 'add', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x+v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x - y 
exports.sub = special(2, 'sub', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x-v))
  xcont = (v) ->  (x = v; ycont(null))
  solver.cont(x, xcont))

# x * y 
exports.mul = special(2, 'mul', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x*v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x / y 
exports.div = special(2, 'div', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x/v))
  xcont = (v) ->  (x = v; ycont(null))
  solver.cont(x, xcont))

# x % y 
exports.mod = special(2, 'mod', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x%v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x && y 
exports.and_ = special(2, 'and_', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x and v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x || y 
exports.or_ = special(2, 'or_', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x and v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# !x 
exports.not_ = special(1, 'not_', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(not v)))

# x << y 
exports.lshift = special(2, 'lshift', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x << v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x >> y 
exports.rshift = special(2, 'rshift', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x >> v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x & y 
exports.bitand = special(2, 'bitand', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x & v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x | y 
exports.bitor = special(2, 'bitor', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x | v))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# ~x 
exports.bitnot = special(1, 'not_', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(~v)))

# Because not using vari.bind, these are not saved in solver.trail  <br/>
# and so it can NOT be restored in solver.failcont <br/>
# EXCEPT the vari has been in solver.trail in the logic branch before vari.binding ++
exports.inc = special(1, 'inc', (solver, cont, vari) ->
  (v) -> cont(++vari.binding))

# vari.binding += 2 
exports.inc2 = special(1, 'inc2', (solver, cont, vari) ->
  (v) -> (vari.binding++; cont(++vari.binding)))

# vari.binding -- 
exports.dec = special(1, 'dec', (solver, cont, vari) ->
  (v) -> (cont(--vari.binding)))

# vari.binding -= 2 
exports.dec2 = special(1, 'dec2', (solver, cont, vari) ->
  (v) -> (vari.binding--; cont(--vari.binding)))

# x.getvalue 
exports.getvalue = special(1, 'getvalue', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(solver.trail.getvalue(v))))

# x.length 
exports.length = special(1, 'length', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(v.length)))

# -x 
exports.neg = special(1, 'neg', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(-v)))

# Math.abs(x) 
exports.abs = special(1, 'abs', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(Math.abs(v))))

# x[y] 
exports.index = special(2, 'index', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x[y]))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x[0] 
exports.first = exports.head = special(1, 'first', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(v[0])))

# x[1...] 
exports.tail = special(1, 'tail', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(v[1...])))

# x[1] 
exports.second = special(1, 'second', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(v[1])))

# x[2] 
exports.third = special(1, 'third', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(v[2])))

# x.concat(y) 
exports.concat = special(2, 'concat', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x.concat(y)))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# list(args...) return an array 
exports.list = special([], 'list', (solver, cont, args...) ->
  solver.argsCont(args, cont))

# x.push(y) 
exports.push = special(2, 'push', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) -> cont(x.push(v)))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x.push(y), when backtracking here, x.pop() 
exports.pushp = special(2, 'pushp', (solver, cont, x, y) ->
  ycont =  solver.cont(y, (v) ->
    fc = solver.failcont
    solver.failcont = (v) -> x.pop(); fc(v)
    cont(x.push(v)))
  xcont = (v) ->  x = v; ycont(null)
  solver.cont(x, xcont))

# x is a free variable? <br/>
# different from logic.freep, this never fail
exports.free = special(1, 'freep', (solver, cont, x) ->
  (v) -> cont(solver.trail.deref(x) instanceof Var))

# toString: x.toString
exports.toString = special(1, 'toString', (solver, cont, x) ->
  solver.cont(x, (v) -> cont(v?.toString?() or JSON.stringify(v))))
