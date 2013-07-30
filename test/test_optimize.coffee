_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("../lib/interlang")

{Compiler, OptimizationEnv} = require '../lib/core'

solve = (exp) ->
  path = process.cwd()+'/lib/compiled.js'
  compile(exp, path)
  delete require.cache[require.resolve(path)]
  compiled = require(path)
  compiled.main()

compile = (exp, path) ->
  code = "_ = require('underscore');\n"\
  +'__slice = [].slice\n'\
  +"solve = require('../lib/core').solve;\n"\
  +"parser = require('../lib/parser');\n"\
  +"solvecore = require('../lib/solve');\n"\
  +"Solver = solvecore.Solver;\n"\
  +"Trail = solvecore.Trail;\n"\
  +"Var = solvecore.Var;\n"\
  +"DummyVar = solvecore.DummyVar;\n\n"\
  +compileToCode(exp)\
    +"\n//exports.main();"
  code = beautify(code, { indent_size: 2})
  fd = fs.openSync(path, 'w')
  fs.writeSync fd, code
  fs.closeSync fd
  path

compiler = new Compiler()
uservar = (name) -> compiler.newvar(il.uservar(name))
internalconst = (name) -> compiler.newconst(il.internalvar(name))
internalvar = (name) -> compiler.newvar(il.internalvar(name))

compileToCode = (exp) ->
  lamda = il.userlamda([], exp)
  lamda = compiler.optimize(lamda, compiler.env)
  lamda = lamda.jsify(compiler, compiler.env)
  f = il.assign(il.uservarattr('exports.main'), lamda)
  f.toCode(compiler)

vari = (name) -> internalconst(name)

xexports = {}

exports.Test =
  "test1": (test) ->
    compiler.env = env = new OptimizationEnv(env, {})
    test.equal  solve(1), 1
    test.equal  solve(il.let_([], 1)), 1
    x = internalconst('x')
    test.equal  solve(il.assign(x, il.let_([], 1))), 1
    x = internalconst('x')
    test.equal  solve(il.begin(il.assign(x, il.let_([], 1)), 2)), 2
    x = internalconst('x')
    test.equal  solve(il.let_([], il.assign(x, 1), 1)), 1
    x = internalvar('x')
    test.equal  solve(il.let_([x, 1], il.assign(x, il.add(x,1)), x)), 2
    x = internalconst('x'); x2 = internalconst('x2')
    test.equal  solve(il.let_([x, 1],il.let_([x2,2], x2), x)), 1
    test.done()

#xexports.Test =
  "test lamda call": (test) ->
    compiler.env = env = new OptimizationEnv(env, {})
    x = internalconst('x')
    f = internalconst('f')
    test.equal  solve(il.if_(1, 2, 3)), 2
    test.equal  solve(il.let_([x, 1], il.if_(1, 2, 3))), 2
    f = internalconst('f')
    test.equal  solve(il.begin(il.assign(f, il.lamda([], 0)), f.call())), 0
    x = uservar('x'); f = internalconst('f')
    test.equal  solve(il.begin(il.assign(f, il.lamda([x], il.if_(il.eq(x,0), 0, f.call(il.sub(x, 1))))), f.call(5))), 0
    x = uservar('x'); f = internalconst('f')
    test.equal  solve(il.begin(il.assign(f, il.lamda([x], il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call(x))))), f.call(1000))), 0
    x = uservar('x'); f = internalconst('f')
    test.equal  solve(il.begin(il.assign(x, 1000),
                               il.assign(f, il.lamda([], il.nonlocal(x), il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call())))),
                               f.call())), 0
    x = uservar('x'); f = internalconst('f')
    test.equal  solve(il.begin(il.assign(x, 1000),
                               il.assign(f, il.lamda([], il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call())))),
                               f.call())), 0
    test.done()

#xexports.Test =
  "test uservar": (test) ->
    compiler.env = env = new OptimizationEnv(env, {})
    x = uservar('x')
    f = internalconst('f')
    v = internalconst('v')
    test.equal  solve(il.begin(il.assign(f, il.userlamda([], il.clamda(v, il.assign(x, il.add(x, 1)), x))), 1)), 1
    test.done()

#xexports.Test =
  "test optrec idfunc": (test) ->
    compiler.env = env = new OptimizationEnv(env, {})
    x = uservar('x')
    f = internalconst('f')
    test.equal  solve(il.begin(il.assign(f, il.optrec([x],  il.if_(il.eq(x,0), 0, f.call(il.sub(x, 1))))), f.call(3))), 0
    test.done()

#exports.Test =
  "test tailrec fibonacci": (test) ->
    compiler.env = env = new OptimizationEnv(env, {})
    n = uservar('n'); a = uservar('a'); b = uservar('b')
    f = internalconst('f')
#    test.equal  solve(il.add(1,2)), 3
    test.equal  solve(il.begin(il.assign(f, il.tailrec([n, a, b],  il.if_(il.eq(n,0), a, f.call(il.sub(n, 1), b, il.add(a, b))))), f.call(3, 0, 1))), 2
    test.done()

#exports.Test =
  "test assign in if_": (test) ->
    compiler.env = env = new OptimizationEnv(env, {})
    n = uservar('n'); a = uservar('a'); b = uservar('b')
    f = internalconst('f')
    #    test.equal  solve(il.add(1,2)), 3
    solve(il.lamda([n],  il.assign(a, 1), il.if_(n, il.assign(a, 2), il.assign(a, 3)), il.add(a, 1)))
    test.done()
