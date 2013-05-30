#{solve} = core = require('../core')

xexports = {}

exports.Test =
  "test 1": (test) ->
    x = null
    cont = (v) -> v
    ycont =  (v) -> ((v) -> cont(x+v))(2)
    xcont = (v) ->  x = v; ycont(null)
    f = (v) -> xcont(1)
    test.equal  f(null), 3
#    test.equal  solve(1), 1
    test.done()

done = (exp) -> (v) -> exp

#print(x)

compile = (exp, cont) -> cont(exp)

compile_print = (exp, cont) ->
  f = compile(null, cont)
  (exp0) ->
    console.log(exp);
    f(null)

exports.Test =
  "test 1": (test) ->
    x = 0
    f = (x) ->
      f1 = -> x
    console.log(f(x).toString())
    f = compile(2, done)
    console.log(f.toString())
    test.equal  f(null), 2
    f2 = compile_print(1, done)
    console.log(f2.toString())
    test.equal  f2(0), null
    test.done()
