# ##dao
_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("./interlang")

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
    @specials[head].call(this, cont, exp[1...]...)

  specials:
    "quote": (cont, exp) -> cont.call(exp)
    'var': (cont, name) -> cont.call(il.vari(name))
    "begin": (cont, exps...) -> @expsCont(exps, cont)
    "assign": (cont, left, exp) ->
        if not _.isArray(left) then throw "Assign's left side should be an sexpression."
        length = left.length
        if length is 0 then throw "Assign's left side should not be empty list."
        head = left[0]
        if not _.isString(head) then throw "Keyword should be a string."
        if  head is "var"
          v = il.vari('v')
          @cont(exp, il.clamda(v, il.assign(il.vari(left[1]), v), cont.call(v)))
        else if head is "index"
          object = left[1]; index = left[2]
          obj = il.vari('obj'); i = il.vari('i'); v = il.vari('v')
          @cont(object, il.clamda(obj, @cont(index, il.clamda(i,  @cont(exp, il.clamda(v,  il.assign(il.index(obj, i), v)))))))
    "if": (cont, test, then_, else_) ->
        v = il.vari('v')
        @cont(test, il.clamda(v, il.if_(v, @cont(then_, cont),
                                             @cont(else_, cont))))
    "jsfun": (cont, func) ->
      v = il.vari('v')
      @cont(func, il.clamda(v, cont.call(il.jsfun(v))))

    "lambda": (cont, params, body...) ->
      k = il.vari('cont')
      params = (il.vari(p[1]) for p in params)
      cont.call(il.lamda([k].concat(params), @expsCont(body, k)))

    "macro": (cont, params, body...) ->
      k = il.vari('cont')
      params1 = (il.vari(p[1]) for p in params)
      body = (@substMacroArgs(e, params) for e in body)
      cont.call(il.lamda([k].concat(params1), @expsCont(body, k)))

    "evalarg": (cont, name) -> cont.call(il.vari(name).call(cont))

    "funcall": (cont, caller, args...) ->
      compiler = @
      f = il.vari('f')
      length = args.length
      params = (il.vari('a'+i) for i in [0...length])
      cont = f.apply([cont].concat(params))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], il.clamda(params[i], cont))
      @cont(caller, il.clamda(f, cont))

    "macall": (cont, caller, args...) ->
      compiler = @
      f = il.vari('f'); v = il.vari('v')
      length = args.length
      params = (il.vari('a'+i) for i in [0...length])
      cont = f.apply([cont].concat(params))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          il.clamda(params[i], cont).call(il.lamda([], compiler.cont(args[i], il.clamda(v, v))))
      @cont(caller, il.clamda(f, cont))

    "let": (cont, bindings, body...) ->
        todo

    "jsmacro": (cont, func) -> todo

    "eval": (cont, exp) ->
        v = compiler.vari('v')
        compiler.cont(exp[1], il.clamda(v, compiler.cont(v, cont)))
  Compiler = @
  for name, vop of il
    if vop instanceof il.VirtualOperation
      do (name=name, vop=vop) -> Compiler::specials['vop_'+name] = (cont, args...) ->
        compiler = @
        length = args.length
        params = (il.vari('a'+i) for i in [0...length])
        cont = cont.call(vop.apply(params))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(params[i], cont))
        cont


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

  substMacroArgs: (exp, params) ->
    if not _.isArray(exp) then return exp
    length = exp.length
    if length is 0 then return exp
    head = exp[0]
    if not _.isString(head) then return exp
    if not @specials.hasOwnProperty(head) then return exp
    if exp in params then return ['evalarg', exp[1]]
    if head is 'lambda' or head is 'macro'
      params = (e for e in params if e not in exp[1])
      exp[0..1].concat(@substMacroArgs(e, params) for e in exp[2...])
    else if head is 'quote' then exp
    else if head is 'quasiquote' then exp
    else [exp[0]].concat(@substMacroArgs(e, params) for e in exp[1...])

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
