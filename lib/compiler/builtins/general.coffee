# #### general builtins

core = require "../core"
clamda = core.clamda

il = require "../interlang"

fun = core.fun
special = core.special

# console.log(arguments) 
exports.print_ = special(null, 'print', (compiler, cont, args...) ->
  compiler.argsCont(args, clamda(args, il.print(args...), il.return(cont, null))))

# x === y 
exports.eq = special(2, 'eq', (compiler, cont, x, y) ->
  x1 = compiler.vari('x')
  y1 = compiler.vari('y')
  compiler.cont(x, clamda(x1, compiler.cont(y, clamda(y1, cont.call(il.eq(x1, y1))).call(null)).call(null))))

# x !== y 
exports.ne = special(2, 'ne', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x!=v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x < y 
exports.lt = special(2, 'lt', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x<=v))
  xcont = (v) ->  (x = v; ycont(null))
  compiler.cont(x, xcont))

# x <= y 
exports.le = special(2, 'le', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x<=v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

#  x > y 
exports.gt = special(2, 'gt', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x>v))
  xcont = (v) ->  (x = v; ycont(null))
  compiler.cont(x, xcont))

# x >= y 
exports.ge = special(2, 'ge', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x>=v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x + y 
exports.add = special(2, 'add', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x+v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x - y 
exports.sub = special(2, 'sub', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x-v))
  xcont = (v) ->  (x = v; ycont(null))
  compiler.cont(x, xcont))

# x * y 
exports.mul = special(2, 'mul', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x*v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x / y 
exports.div = special(2, 'div', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x/v))
  xcont = (v) ->  (x = v; ycont(null))
  compiler.cont(x, xcont))

# x % y 
exports.mod = special(2, 'mod', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x%v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x && y 
exports.and_ = special(2, 'and_', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x and v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x || y 
exports.or_ = special(2, 'or_', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x and v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# !x 
exports.not_ = special(1, 'not_', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(not v)))

# x << y 
exports.lshift = special(2, 'lshift', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x << v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x >> y 
exports.rshift = special(2, 'rshift', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x >> v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x & y 
exports.bitand = special(2, 'bitand', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x & v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x | y 
exports.bitor = special(2, 'bitor', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x | v))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# ~x 
exports.bitnot = special(1, 'not_', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(~v)))

# Because not using vari.bind, these are not saved in compiler.trail  <br/>
# and so it can NOT be restored in compiler.failcont <br/>
# EXCEPT the vari has been in compiler.trail in the logic branch before vari.binding ++
exports.inc = special(1, 'inc', (compiler, cont, vari) ->
  (v) -> cont(++vari.binding))

# vari.binding += 2 
exports.inc2 = special(1, 'inc2', (compiler, cont, vari) ->
  (v) -> (vari.binding++; cont(++vari.binding)))

# vari.binding -- 
exports.dec = special(1, 'dec', (compiler, cont, vari) ->
  (v) -> (cont(--vari.binding)))

# vari.binding -= 2 
exports.dec2 = special(1, 'dec2', (compiler, cont, vari) ->
  (v) -> (vari.binding--; cont(--vari.binding)))

# x.getvalue 
exports.getvalue = special(1, 'getvalue', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(compiler.trail.getvalue(v))))

# x.length 
exports.length = special(1, 'length', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(v.length)))

# -x 
exports.neg = special(1, 'neg', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(-v)))

# Math.abs(x) 
exports.abs = special(1, 'abs', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(Math.abs(v))))

# x[y] 
exports.index = special(2, 'index', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x[y]))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x[0] 
exports.first = exports.head = special(1, 'first', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(v[0])))

# x[1...] 
exports.tail = special(1, 'tail', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(v[1...])))

# x[1] 
exports.second = special(1, 'second', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(v[1])))

# x[2] 
exports.third = special(1, 'third', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(v[2])))

# x.concat(y) 
exports.concat = special(2, 'concat', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x.concat(y)))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# list(args...) return an array 
exports.list = special([], 'list', (compiler, cont, args...) ->
  compiler.argsCont(args, cont))

# x.push(y) 
exports.push = special(2, 'push', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) -> cont(x.push(v)))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x.push(y), when backtracking here, x.pop() 
exports.pushp = special(2, 'pushp', (compiler, cont, x, y) ->
  ycont =  compiler.cont(y, (v) ->
    fc = compiler.failcont
    compiler.failcont = (v) -> x.pop(); fc(v)
    cont(x.push(v)))
  xcont = (v) ->  x = v; ycont(null)
  compiler.cont(x, xcont))

# x is a free variable? <br/>
# different from logic.freep, this never fail
exports.free = special(1, 'freep', (compiler, cont, x) ->
  (v) -> cont(compiler.trail.deref(x) instanceof Var))

# toString: x.toString
exports.toString = special(1, 'toString', (compiler, cont, x) ->
  compiler.cont(x, (v) -> cont(v?.toString?() or JSON.stringify(v))))
