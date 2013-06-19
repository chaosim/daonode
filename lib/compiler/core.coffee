# ##dao
_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("./interlang")

exports.solve = (exp, path) ->
  path = compile(exp, path)
  delete require.cache[require.resolve(path)]
  require(path).main()

compile = (exp, path) ->
  compiler = new Compiler()
  code = "solve = require('f:/daonode/lib/compiler/core.js').solve;\n"\
  +"solveModule = require('f:/daonode/lib/compiler/solve.js');\n"\
  +"solver = new solveModule.Solver()\n"\
  +"Trail = solveModule.Trail\n"\
  +"Var = solveModule.Var\n"\
  +"exports.main = #{compiler.compile(exp)}"\
  +"\n//exports.main();"
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
    @exits = {}
    @continues = {}
    @protect = (cont) -> cont

  compile: (exp) ->
    v = il.vari('v')
    fromCont = @cont(exp, il.clamda(v, v))
    f = il.clamda(v, fromCont)
    f.refMap = {}
    f.analyze(@, f.refMap)
    f = f.optimize(new Env(), @)
    f = f.jsify()
    f.toCode(@)

  # compile to continuation
  cont: (exp, cont) ->
    if _.isString(exp) then return cont.call(il.vari(exp))
    if not _.isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not _.isString(head) then return cont.call(exp)
    if not @specials.hasOwnProperty(head) then return cont.call(exp)
    @specials[head].call(this, cont, exp[1...]...)

  leftValueCont: (cont, task, item, exp, op) ->
    if  _.isString(item)
      v = il.vari('v')
      if task is 'assign' then return @cont(exp, il.clamda(v, il.assign(il.vari(item), v), cont.call(v)))
      else if task is 'augment-assign'
        return @cont(exp, il.clamda(v, new augmentOperators[op](il.vari(item), v), cont.call(v)))
      else return cont.call(il[task].call(il.vari(item)))
    if not _.isArray(item) then throw new Error "Left Value should be an sexpression."
    length = item.length
    if length is 0 then throw new Error "Left Value side should not be empty list."
    head = item[0]
    if not _.isString(head) then throw new Error "Keyword should be a string."
    if head is "index"
      object = item[1]; index = item[2]
      obj = il.vari('obj'); i = il.vari('i'); v = il.vari('v')
      if task is 'assign' then cont1 = @cont(exp, il.clamda(v,  il.assign(il.index.call(obj, i), cont.call(v))))
      else if task is 'augment-assign'
        cont1 = @cont(exp, il.clamda(v,  new augmentOperators[op](il.index.call(obj, i), cont.call(v))))
      else cont1 = cont.call(il[task].call(il.index.call(obj, i)))
      @cont(object, il.clamda(obj, @cont(index, il.clamda(i, cont1))))
    else throw new Error "Left Value side should be assignable expression."

  specials:
    "quote": (cont, exp) -> cont.call(exp)
    "eval": (cont, exp, path) ->
      v = il.vari('v')
      p = il.vari('path')
      @cont(exp, il.clamda(v, @cont(path, il.clamda(p, cont.call(il.evalexpr.call(v, p))))))
    'string': (cont, exp) -> cont.call(exp)
    "begin": (cont, exps...) -> @expsCont(exps, cont)

    "assign": (cont, left, exp) ->  @leftValueCont(cont, "assign", left, exp)
    "augment-assign": (cont, op, left, exp) ->  @leftValueCont(cont, "augment-assign", left, exp, op)
    'inc': (cont, item) -> @leftValueCont(cont, "inc", item)
    'suffixinc': (cont, item) -> @leftValueCont(cont, "suffixinc", item)
    'dec': (item) ->  @leftValueCont(cont, "dec", item)
    'suffixdec': (item) ->  @leftValueCont(cont, "suffixdec", item)

    "if": (cont, test, then_, else_) ->
        v = il.vari('v')
        @cont(test, il.clamda(v, il.if_(v, @cont(then_, cont), @cont(else_, cont))))

    "jsfun": (cont, func) ->
      f = il.jsfun(func)
      f._effect = @_effect
      cont.call(f)

    "pure": (cont, exp) ->
      oldEffect = @_effect
      @_effect = il.PURE
      result = @cont(exp, cont)
      @_effect = oldEffect
      result

    "effect": (cont, exp) ->
      oldEffect = @_effect
      @_effect = il.EFFECT
      result = @cont(exp, cont)
      @_effect = oldEffect
      result

    "io": (cont, exp) ->
      oldEffect = @_effect
      @_effect = il.IO
      result = @cont(exp, cont)
      @_effect = oldEffect
      result

    "lambda": (cont, params, body...) ->
      k = il.vari('cont')
      params = (il.vari(p) for p in params)
      cont.call(il.lamda([k].concat(params), @expsCont(body, k)))

    "macro": (cont, params, body...) ->
      k = il.vari('cont')
      params1 = (il.vari(p) for p in params)
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

    "quasiquote": (cont, exp) -> @quasiquote(exp, cont)

    "unquote": (cont, exp) ->
      throw new Error "unquote: too many unquote and unquoteSlice"

    "unquote-slice": (cont, exp) ->
      throw new Error "unquoteSlice: too many unquote and unquoteSlice"

#    "jsmacro": (cont, func) -> todo

    # lisp style block
    'block': (cont, label, body...) ->
      label = label[1]
      if not _.isString(label) then (label = ''; body = [label].concat(body))
      exits = @exits[label] ?= []
      exits.push(cont)
      defaultExits = @exits[''] ?= []  # if no label, go here
      defaultExits.push(cont)
      continues = @continues[label] ?= []
      f = il.vari('block'+label)
      fun = il.clamda(il.vari('v'), null)
      continues.push(f)
      defaultContinues = @continues[''] ?= []   # if no label, go here
      defaultContinues.push(f)
      fun.body = @expsCont(body, cont)
      exits.pop()
      if exits.length is 0 then delete @exits[label]
      continues.pop()
      if continues.length is 0 then delete @continues[label]
      defaultExits.pop()
      defaultContinues.pop()
      il.begin(il.assign(f, fun), f.apply([null]))

    # break a block
    'break': (cont, label, value) ->
      label = label[1]
      exits = @exits[label]
      if not exits or exits==[] then throw new  Error(label)
      exitCont = exits[exits.length-1]
      @cont(value, @protect(exitCont))

    # continue a block
    'continue': (cont, label) ->
      label = label[1]
      continues = @continues[label]
      if not continues or continues==[] then throw new  Error(label)
      continueCont = continues[continues.length-1]
      @protect(continueCont).call(null)

    # aka. lisp style catch/throw
    'catch': (cont, tag, forms...) ->
      v = il.vari('v'); v2 = il.vari('v2')
      @cont(tag, il.clamda(v,
                           il.pushCatch.apply([v, cont]),
                           @expsCont(forms, il.clamda(v2
                                                      il.popCatch.apply([v]),
                                                      cont.call(v2)))))

    # aka lisp style throw
    "throw": (cont, tag, form) ->
      v = il.vari('v'); v2 = il.vari('v2')
      @cont(tag, il.clamda(v,
                           @cont(form, il.clamda(v2,
                                                 @protect(il.findCatch.apply([v])).call(v2)))))


    # aka. lisp's unwind-protect
    'unwind-protect': (cont, form, cleanup...) ->
      oldprotect = @protect
      v1 = il.vari('v3'); v2 = il.vari('v4')
      compiler = @
      @protect = (cont) -> il.clamda(v1,
                                     compiler.expsCont(cleanup, il.clamda(v2,
                                          oldprotect(cont).call(v1))))
      result = @cont(form,  il.clamda(v1,
                              @expsCont(cleanup, il.clamda(v2,
                                    cont.call(v1)))))
      @protect = oldprotect
      result

    # aka. lisp's call/cc
    # callcc(someFunction(kont) -> body)
    #current continuation @cont can be captured in someFunction
    'callcc': (cont, fun) ->
      v = il.vari('v')
      @cont(fun, il.clamda(v, cont.call(v.call(cont, cont))))

    'logicvar': (cont, name) -> cont.call(il.newLogicVar.call(name))
    'unify': (cont, x, y) ->
      x1 = il.vari('x'); y1 = il.vari('y')
      @cont(x, il.clamda(x1, @cont(y, il.clamda(y1,
          il.if_(il.unify.call(x1, y1), cont.call(true),
             il.failcont.call(false))))))
    'notunify': (cont, x, y) ->
      x1 = il.vari('x'); y1 = il.vari('y')
      @cont(x, il.clamda(x1, @cont(y, il.clamda(y1,
          il.if_(il.unify.call(x, y), il.failcont.call(false),
             cont.call(true))))))
    'succeed': (cont) -> cont.call(true)
    'fail': (cont) -> il.failcont.call(false)
    'orp': (cont, x, y) ->
      v = il.vari('v')
      trail = il.vari('trail')
      state = il.vari('state')
      fc = il.vari('fc')
      il.begin(il.assign(trail, il.trail),
               il.settrail(il.newTrail),
               il.assign(state, il.state),
               il.assign(fc, il.failcont),
               il.setfailcont(il.clamda(v,
                   il.undotrail.call(il.trail),
                   il.settrail(trail),
                   il.setstate(state),
                   il.setfailcont(fc),
                   @cont(y, cont))),
               @cont(x, cont))

      #like in prolog, failure as negation.
    'notp': (cont, goal) ->
      v = il.vari('v')
      trail = il.vari('trail')
      state = il.vari('state')
      fc = il.vari('fc')
      il.begin(
            il.assign(trail, il.trail),
            il.settrail(il.newTrail),
            il.assign(fc, il.failcont),
            il.assign(state, il.state),
            il.setfailcont(il.clamda(v,
              il.undotrail.call(il.trail),
              il.settrail(trail),
              il.setstate(state),
              il.setfailcont(fc),
              cont.call(v))),
            @cont(goal, fc))
    'repeat': (cont) -> il.begin(il.setfailcont(cont), cont.call(null))

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
      else if _.isArray(exp) then JSON.stringify(exp)
      else if typeof exp is 'function' then exp.toString()
      else exp.toString()

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw new  exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else
      v = il.vari('v')
      @cont(exps[0], il.clamda(v, @expsCont(exps[1...], cont)))

  quasiquote: (exp, cont) ->
    if not _.isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not _.isString(head) then return cont.call(exp)
    if not @specials.hasOwnProperty(head) then return cont.call(exp)
    head = exp[0]
    if head is "unquote" then @cont(exp[1], cont)
    else if head is "unquote-slice" then @cont(exp[1], cont)
    else if head is "quote" then cont.call(exp)
    else if head is "string" then cont.call(exp)
    else
      quasilist = il.vari('quasilist')
      v = il.vari('v')
      cont = cont.call(quasilist)
      for i in [exp.length-1..1] by -1
        e = exp[i]
        if  _.isArray(e) and e.length>0 and e[0] is "unquote-slice"
          cont = @quasiquote(e, il.clamda(v, il.assign(quasilist, il.concat.call(quasilist, v)), cont))
        else
          cont = @quasiquote(e, il.clamda(v, il.push.call(quasilist, v), cont))
      il.begin( il.assign(quasilist, il.list.call(head)),
        cont)

  substMacroArgs: (exp, params) ->
    if exp in params then return ['evalarg', exp]
    if not _.isArray(exp) then return exp
    length = exp.length
    if length is 0 then return exp
    head = exp[0]
    if not _.isString(head) then return exp
    if not @specials.hasOwnProperty(head) then return exp
    if head is 'lambda' or head is 'macro'
      params = (e for e in params if e not in exp[1])
      exp[0..1].concat(@substMacroArgs(e, params) for e in exp[2...])
    else if head is 'quote' then exp
    else if head is 'string' then exp
    else if head is 'quasiquote' then exp
    else [exp[0]].concat(@substMacroArgs(e, params) for e in exp[1...])

augmentOperators = {add: il.augadd, sub: il.augsub, mul: il.augmul, div: il.augdiv, mod: il.augmod,
'and': il.augand, 'or': il.augor, bitand: il.augbitand, bitor:il.augbitor, bitxor: il.augbitxor,
lshift: il.auglshift, rshift: il.augrshift
}

exports.Env = class Env
  constructor: (@outer, @data={}) ->
  extend: (vari, value) -> data = {}; data[vari.name] = value; new Env(@, data)
  extendBindings: (bindings) -> new Env(@, bindings)
  lookup: (vari) ->
    data = @data; name = vari.name;
    if data.hasOwnProperty(name) then return data[name]
    else
      outer = @outer
      if outer then outer.lookup(vari) else vari

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

exports.TypeError = class TypeError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error
