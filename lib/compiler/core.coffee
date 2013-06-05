# ##dao
_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("./interlang")

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
    v = il.vari('v')
    fromCont = @cont(exp, il.clamda(v, v))
    f = il.clamda(v, fromCont)
#    f = f.optimize(new Env(), @)
    f = f.jsify()
    "exports.main = #{f.toCode(@)}"

  # compile to continuation
  cont: (exp, cont) ->
    if not _.isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not _.isString(head) then return cont.call(exp)
    if not @specials.hasOwnProperty(head) then return cont.call(exp)
    @specials[head].call(this, exp[1...])
  specials:
    "quote": (cont, exp) -> cont.call(exp)
    "begin": (cont, exps...) -> @expsCont(exp, cont)
    "assign": (cont, left, exp) ->
        if _.isString(left)
          v = il.vari('v')
          return @cont(exp, il.clamda(v, il.assign(il.vari(left), v), cont.call(v)))
        if not _.isArray(left) then throw "should be an sexpression."
        length = left.length
        if left is 0 then throw "should be an sexpression."
        head = left[0]
        if not _.isString(head) then throw "wrong keyword."
        if head is "index"
          object = left[1]; index = left[2]
          obj = il.vari('obj'); i = il.vari('i'); v = il.vari('v')
          @cont(object, il.clamda(obj, @cont(index, il.clamda(i,  @cont(exp, il.clamda(v,  il.assign(il.index(obj, i), v)))))))
    "if": (cont, test, then_, else_) ->
        v = il.vari('v')
        compiler.cont(test, il.clamda(v, il.if_(v, compiler.cont(then_, cont),
                                             compiler.cont(else_, cont))))
    'var': (cont, name) ->
        todo
    "jsfun": (cont, func) ->
        todo
    "jsmacro": (cont, func) -> todo
    "lamdda": (cont, params, body...) ->
        params = exp[1]; body = exp[2...]
        k = compiler.vari('k')
        il.lamda([k].concat(params), compiler.cont(body, k))
    "macro": (cont, params, body...) ->
        params = exp[1]; body = exp[2...]
        k = compiler.vari('k')
        il.lamda([k].concat(params), compiler.cont(body, k))
    "let": (cont, bindings, body...) ->
        todo
    "funcall": (cont, caller, args...) ->
        params = (compiler.vari('a') for x in args)
        fun = exp[1]
        args = exp[2...]
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(params[i], cont))
        cont
    "macrocall": (cont, caller, args...) ->
        m = exp[1]
    "eval": (cont, exp) ->
        v = compiler.vari('v')
        compiler.cont(exp[1], il.clamda(v, compiler.cont(v, cont)))

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
      v = il.vari('v')
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

# A flag class is used to process unquoteSlice
UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

exports.TypeError = class TypeError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error
