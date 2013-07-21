_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("../interlang")

{Compiler, OptimizationEnv} = require '../core'

solve = (exp, path) ->
  path = compile(exp, path)
  delete require.cache[require.resolve(path)]
  compiled = require(path)
  compiled.main()

compile = (exp, path) ->
  code = "_ = require('underscore');\n"\
  +'__slice = [].slice\n'\
  +"solve = require('f:/daonode/lib/compiler/core.js').solve;\n"\
  +"parser = require('f:/daonode/lib/compiler/parser.js');\n"\
  +"solvecore = require('f:/daonode/lib/compiler/solve.js');\n"\
  +"SolverFinish = solvecore.SolverFinish;\n"\
  +"Solver = solvecore.Solver;\n"\
  +"Trail = solvecore.Trail;\n"\
  +"Var = solvecore.Var;\n"\
  +"DummyVar = solvecore.DummyVar;\n\n"\
  +compileToCode(exp)\
    +"\n//exports.main();"
  code = beautify(code, { indent_size: 2})
  path = path or "f:/daonode/lib/compiler/test/compiled.js"
  fd = fs.openSync(path, 'w')
  fs.writeSync fd, code
  fs.closeSync fd
  path

compiler = new Compiler()
uservar = (name) -> compiler.newvar(il.uservar(name))
internalvar = (name) -> compiler.newvar(il.internalvar(name))
compiler.env = env = new OptimizationEnv(env, {})

compileToCode = (exp) ->
  lamda = il.userlamda([], exp)
  lamda = compiler.optimize(lamda, env)
  lamda = lamda.jsify(compiler, env)
  f = il.assign(il.uservarattr('exports.main'), lamda)
  f.toCode(compiler)

vari = (name) -> internalvar(name)

xexports = {}

exports.Test =
  "test1": (test) ->
    x = internalvar('x')
    x2 = internalvar('x2')
    test.equal  solve(1), 1
    test.equal  solve(il.let_([], 1)), 1
    test.equal  solve(il.assign(x, il.let_([], 1))), 1
    test.equal  solve(il.begin(il.assign(x, il.let_([], 1)), 2)), 2
    test.equal  solve(il.let_([], il.assign(x, 1), 1)), 1
    test.equal  solve(il.let_([x, 1], il.assign(x, il.add(x,1)), x)), 2
    test.equal  solve(il.let_([x, 1],il.let_([x2,2], x2), x)), 1
    test.done()

#xexports.Test =
  "test lamda call": (test) ->
    x = internalvar('x')
    f = internalvar('f')
    test.equal  solve(il.if_(1, 2, 3)), 2
    test.equal  solve(il.let_([x, 1], il.if_(1, 2, 3))), 2
    test.equal  solve(il.begin(il.assign(f, il.lamda([], 0)), f.call())), 0
    test.equal  solve(il.begin(il.assign(f, il.lamda([x], il.if_(il.eq(x,0), 0, f.call(il.sub(x, 1))))), f.call(5))), 0
    test.equal  solve(il.begin(il.assign(f, il.lamda([x], il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call(x))))), f.call(1000))), 0
    test.equal  solve(il.begin(il.assign(x, 1000),
                               il.assign(f, il.lamda([], il.nonlocal(x), il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call())))),
                               f.call())), 0
    x = uservar('x')
    test.equal  solve(il.begin(il.assign(x, 1000),
                               il.assign(f, il.lamda([], il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call())))),
                               f.call())), 0
    test.done()

#xexports.Test =
  "test uservar": (test) ->
    x = uservar('x')
    f = internalvar('f')
    v = internalvar('v')
    test.equal  solve(il.begin(il.assign(f, il.userlamda([], il.clamda(v, il.assign(x, il.add(x, 1)), x))), 1)), 1
    test.done()

#xexports.Test =
  "test optrec idfunc": (test) ->
    x = uservar('x')
    f = internalvar('f')
    test.equal  solve(il.begin(il.assign(f, il.optrec([x],  il.if_(il.eq(x,0), 0, f.call(il.sub(x, 1))))), f.call(3))), 0
    test.done()

#exports.Test =
  "test tailrec fibonacci": (test) ->
    n = uservar('n'); a = uservar('a'); b = uservar('b')
    f = internalvar('f')
#    test.equal  solve(il.add(1,2)), 3
    test.equal  solve(il.begin(il.assign(f, il.tailrec([n, a, b],  il.if_(il.eq(n,0), a, f.call(il.sub(n, 1), b, il.add(a, b))))), f.call(3, 0, 1))), 2
    test.done()

exports.Test =
  "test switch": (test) ->
    a = 0; b = 1; c = 3;
    `switch (a){ case b: case c: break}`
    test.done()
