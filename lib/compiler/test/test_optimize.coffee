_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("../interlang")

{Compiler, Env} = require '../core'

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
  v = il.vari('v')
  f = il.assign(il.vari('exports.main'), il.clamda(v, exp))
  f.refMap = {}
  f.analyze(compiler, f.refMap)
  f = f.optimize(new Env(), compiler)
  f = f.jsify()
  f.toCode(compiler)

vari = (name) -> il.vari(name)

xexports = {}

exports.Test =
  "test vari assign": (test) ->
    x = il.vari('x')
#    test.equal  solve(il.let_([x, 1], il.addassign(x, 1), x)), 2
    test.equal  solve(il.let_([x, 1],il.let_([x,2], x), x)), 1
    test.done()

