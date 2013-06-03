# ##dao

fs = require("fs")
il = require("./interlang")
solve = require('./solve')
beautify = require('js-beautify').js_beautify

keywords = require('./keywords')

exports.solve = (exp) ->
  path = compile(exp)
  delete require.cache[require.resolve(path)]
  require(path).main()

compile = (exp) ->
  compiler = new Compiler()
  code = compiler.compile(exp)
  code = beautify(code, { indent_size: 2})
  path = path or "f:/daonode/lib/compiler/test/compiled.js"
  fd = fs.openSync(path, 'w')
  fs.writeSync fd, code
  fs.closeSync fd
  path

# ####class Compiler
# the compiler for dao expression
exports.Compiler = class Compiler
  constructor: () ->
    @nameToVarIndex = {}

  compile: (exp) ->
    v = vari('v')
    fromCont = @cont(exp, il.clamda(v, v))
    f = il.clamda(v, fromCont)
#    f = f.optimize(new Env(), @)
    f = f.jsify(@)
    "exports.main = #{f.toCode(@)}"

  # compile to continuation
  cont: (exp, cont) ->
    length = exp.length
    if length is 0 then cont.call(exp)
    else
      head = exp[0]
      if head typeof Number
        switch head
          when keywords.quote then cont.call(exp[1])
          when keywords.eval_
            v = compiler.vari('v')
            compiler.cont(exp[1], il.clamda(v, compiler.cont(v, cont)))
          when keywords.begin then @expsCont(exp[1...], cont)
          when keywords.assign
            v = compiler.vari('v')
            compiler.cont(exp[1], il.clamda(v, il.assign(exp[2].interlang(), v), cont.call(v)))
          when keywors.if_
            v = @vari('v')
            compiler.cont(exp[1], il.clamda(v, il.if_(v, compiler.cont(exp[2], cont),
                                                 compiler.cont(exp[3], cont))))
          when keywords.vari
            todo
          when keywords.jsfun
            todo
          when keywords.jsmacro
            todo
          when keywords.lamda
            params = exp[1]; body = exp[2...]
            k = compiler.vari('k')
            il.lamda([k].concat(params), compiler.cont(body, k))
          when keywords.macro
            params = exp[1]; body = exp[2...]
            k = compiler.vari('k')
            il.lamda([k].concat(params), compiler.cont(body, k))
          when keywords.let_
            todo
          when keywords.funcall
            params = (compiler.vari('a') for x in args)
            fun = exp[1]
            args = exp[2...]
            for i in [length-1..0] by -1
              cont = do (i=i, cont=cont) ->
                compiler.cont(args[i], il.clamda(params[i], cont))
            cont
          when keywords.macrocall
            m = exp[1]
          else cont.call(exp)
      else cont.call(exp)

  optimize: (exp, env) ->
    expOptimize = exp?.optimize
    if expOptimize then expOptimize.call(exp, env, @)
    else exp

  toCode: (exp) ->
    exptoCode = exp?.toCode
    if exptoCode then exptoCode.call(exp, @)
    else
      if exp is undefined then 'undefined'
      else if exp is null then 'null'
      else if _.isNumber(exp) then exp.toString()
      else if _.isString(exp) then JSON.stringify(exp)
      else if exp is true then "true"
      else if exp is false then "false"
      else throw new TypeError(exp)

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else
      v = @vari('v')
      @cont(exps[0], il.clamda(v, @expsCont(exps[1...], cont)))

  argsCont: (args, cont) ->
    length = args.length
    params = @vari('a') for x in args
    cont = cont.call(params)
    compiler = @
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.cont(args[i], il.clamda(params[i], cont))
    cont

  # used by lisp style quasiquote, unquote, unquoteSlice
  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v) -> cont(exp))

class Env
  constructor: (@outer, @data={}) ->
  extend: (vari, value) -> data = {}; data[vari.name] = value; new Env(@, data)
  lookup: (vari) ->
    data = @data; name = vari.name;
    if data.hasOwnProperty(name) then return data[name]
    else
      outer = @outer
      if outer then outer.lookup(vari) else vari

# ####class Var
# Var for logic bindings, used in unify, lisp.assign, inc/dec, parser operation, etc.
exports.Var = class Var
  constructor: (@name) ->
  cont: (compiler, cont) -> il.return(cont.call(il.deref(@interlang())))
  interlang: () -> il.vari(@name)
  toString:() -> "vari(#{@name})"

reElements = /\s*,\s*|\s+/

# utilities for new variables
exports.vari = (name) ->  new Var(name)
exports.vars = (names) -> vari(name) for name in split names,  reElements

# A flag class is used to process unquoteSlice
UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

# generate a instance of Macro from a function <br/>
#  example:   <br/>
#  orpm = fun((x, y) -> orp(x,y ) # coffeescript<br/>
#  orpm = fun(function(x,y){  return orp(x,y ); } # javascript
exports.macro = commandMaker(exports.Macro)

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

exports.TypeError = class TypeError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error
