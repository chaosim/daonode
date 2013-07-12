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

compileToCode = (exp) ->
  compiler = new Compiler()
  v = il.internallocal('v')
  lamda = il.clamda(v, exp)
  env = new OptimizationEnv(env, {})
  lamda = compiler.optimize(lamda, env)
  lamda = lamda.jsify(@, env)
  f = il.assign(il.usernonlocalattr('exports.main'), lamda)
  f.toCode(compiler)

vari = (name) -> il.internallocal(name)

xexports = {}

exports.Test =
  "test1": (test) ->
    x = il.internallocal('x')
    x2 = il.internallocal('x2')
    test.equal  solve(1), 1
    test.equal  solve(il.let_([], 1)), 1
    test.equal  solve(il.assign(x, il.let_([], 1))), 1
    test.equal  solve(il.begin(il.assign(x, il.let_([], 1)), 2)), 2
    test.equal  solve(il.let_([], il.assign(x, 1), 1)), 1
    test.equal  solve(il.let_([x, 1], il.assign(x, il.add(x,1)), x)), 2
    test.equal  solve(il.let_([x, 1],il.let_([x2,2], x2), x)), 1
    test.done()

exports.Test =
  "test lamda call": (test) ->
    x = il.internallocal('x')
    f = il.internallocal('f')
#    test.equal  solve(il.if_(1, 2, 3)), 2
#    test.equal  solve(il.let_([x, 1], il.if_(1, 2, 3))), 2
#    test.equal  solve(il.begin(il.assign(f, il.lamda([], 0)), f.call())), 0
#    test.equal  solve(il.begin(il.assign(f, il.lamda([x], il.if_(il.eq(x,0), 0, f.call(il.sub(x, 1))))), f.call(5))), 0
    test.equal  solve(il.begin(il.assign(f, il.lamda([x], il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call(x))))), f.call(1000))), 0
#    test.equal  solve(il.begin(il.assign(x, 1000),
#                               il.assign(f, il.lamda([], il.if_(il.eq(x,0), 0, il.begin(il.assign(x, il.sub(x, 1)), f.call())))),
#                               f.call())), 0
    test.done()

xexports.Test =
  "test userlocal": (test) ->
    x = il.userlocal('x')
    f = il.internallocal('f')
    v = il.internallocal('v')
    test.equal  solve(il.begin(il.assign(f, il.userlamda([], il.clamda(v, il.assign(x, il.add(x, 1)), x))), 1)), 1
    test.done()


exports.Test =
  "test label": (test) ->
    x = 5
    `label1://`
    while 1
      if not x
        do -> `break label1`;1
      else console.log x--
    test.done()

