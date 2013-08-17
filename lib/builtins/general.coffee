# #### general builtins

core = require "../core"
il = require "../interlang"

fun = core.fun
special = core.special

# console.log(arguments) 
exports.print_ = fun(null, 'print',il.jscallable('console.log'))

exports.eq = fun(2, 'eq', il.eq)
exports.ne = fun(2, 'ne', il.ne)
exports.lt = fun(2, 'lt', il.lt)
exports.le = fun(2, 'le', il.le)
exports.gt = fun(2, 'gt', il.gt)
exports.ge = fun(2, 'ge', il.ge)
exports.add = fun(2, 'add', il.add)
exports.sub = fun(2, 'sub', il.sub)
exports.mul = fun(2, 'mul', il.mul)
exports.div = fun(2, 'div', il.div)
exports.and_ = fun(2, 'and_', il.and_)
exports.or_ = fun(2, 'or_', il.or_)
exports.not_ = fun(1, 'not_', il.not_)
exports.lshift = fun(2, 'lshift', il.lshift)
exports.rshift = fun(2, 'rshift', il.rshift)
exports.bitand = fun(2, 'bitand', il.bitand)
exports.bitor = fun(2, 'bitor', il.bitor)
exports.bitnot = fun(1, 'bitnot', il.bitnot)


exports.inc = special(1, 'inc', (compiler, cont, item) ->
  il.return(cont.call(il.inc.apply([item.interlang()]))))

exports.suffixinc = special(1, 'suffixinc', (compiler, cont, item) ->
  il.return(cont.call(il.suffixinc.apply([item.interlang()]))))

exports.dec = special(1, 'dec', (compiler, cont, item) ->
  il.return(cont.call(il.dec.apply([item.interlang()]))))

exports.suffixdec = special(1, 'suffixdec', (compiler, cont, item) ->
  il.return(cont.call(il.suffixdec.apply([item.interlang()]))))

###
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
###