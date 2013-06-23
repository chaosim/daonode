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
  code = "_ = require('underscore');\n"\
  +"solve = require('f:/daonode/lib/compiler/core.js').solve;\n"\
  +"parser = require('f:/daonode/lib/compiler/parser.js');\n"\
  +"solvecore = require('f:/daonode/lib/compiler/solve.js');\n"\
  +"Solver = solvecore.Solver;\n"\
  +"Trail = solvecore.Trail;\n"\
  +"Var = solvecore.Var;\n\n"\
  +compiler.compile(exp)\
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
    fromCont = @cont(exp, il.idcont)
    f = il.assign(il.vari('exports.main'), il.clamda(v
          il.assign(il.solver, il.new(il.symbol('Solver').call())),
          il.assign(il.state, null),
          il.assign(il.catches, {}),
          il.assign(il.trail, il.newTrail),
          il.assign(il.failcont, il.idcont),
          il.assign(il.cutcont, il.failcont),
          fromCont))
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
      else return cont.call(il[task](il.vari(item)))
    if not _.isArray(item) then throw new Error "Left Value should be an sexpression."
    length = item.length
    if length is 0 then throw new Error "Left Value side should not be empty list."
    head = item[0]
    if not _.isString(head) then throw new Error "Keyword should be a string."
    if head is "index"
      object = item[1]; index = item[2]
      obj = il.vari('obj'); i = il.vari('i'); v = il.vari('v')
      if task is 'assign' then cont1 = @cont(exp, il.clamda(v,  il.assign(il.index(obj, i), cont.call(v))))
      else if task is 'augment-assign'
        cont1 = @cont(exp, il.clamda(v,  new augmentOperators[op](il.index(obj, i), cont.call(v))))
      else cont1 = cont.call(il[task](il.index(obj, i)))
      @cont(object, il.clamda(obj, @cont(index, il.clamda(i, cont1))))
    else throw new Error "Left Value side should be assignable expression."

  specials:
    "quote": (cont, exp) -> cont.call(exp)
    "eval": (cont, exp, path) ->
      v = il.vari('v')
      p = il.vari('path')
      @cont(exp, il.clamda(v, @cont(path, il.clamda(p, cont.call(il.evalexpr(v, p))))))
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
          il.clamda(params[i], cont).call(il.lamda([], compiler.cont(args[i], il.idcont)))
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
                           il.pushCatch(v, cont),
                           @expsCont(forms, il.clamda(v2
                                                      il.popCatch(v),
                                                      cont.call(v2)))))

    # aka lisp style throw
    "throw": (cont, tag, form) ->
      v = il.vari('v'); v2 = il.vari('v2')
      @cont(tag, il.clamda(v,
                           @cont(form, il.clamda(v2,
                                                 @protect(il.findCatch(v)).call(v2)))))


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
          il.if_(il.unify(x1, y1), cont.call(true),
             il.failcont.call(false))))))
    'notunify': (cont, x, y) ->
      x1 = il.vari('x'); y1 = il.vari('y')
      @cont(x, il.clamda(x1, @cont(y, il.clamda(y1,
          il.if_(il.unify(x, y), il.failcont.call(false),
             cont.call(true))))))
    # evaluate @exp and bind it to vari
    'is': (cont, vari, exp) ->
      v = il.vari('v')
      @cont(exp, il.clamda(v, il.bind(vari, v), cont.call(true)))
    'bind': (cont, vari, term) -> il.begin(il.bind(vari, il.deref(term)), cont.call(true))
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
                   il.undotrail(il.trail),
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
              il.undotrail(il.trail),
              il.settrail(trail),
              il.setstate(state),
              il.setfailcont(fc),
              cont.call(v))),
            @cont(goal, fc))
    'repeat': (cont) -> il.begin(il.setfailcont(cont), cont.call(null))
    #  make the goal cutable
    'cutable': (cont, goal) ->
      cc = il.vari('cutcont')
      v = il.vari('v')
      il.begin(il.assign(cc, il.cutcont),
               il.assign(il.cutcont, il.failcont),
               @cont(goal, il.clamda(v, il.assign(il.cutcont, cc), cont.call(v))))
    # prolog's cut, aka "!"
    'cut': (cont) -> il.begin(il.setfailcont(il.cutcont), cont.call(null))
    # find all solution to the goal @exp in prolog
    'findall': (cont, goal) ->
      fc = il.vari('fc')
      v = il.vari('v')
      il.let_([fc, il.failcont],
               il.setfailcont(il.clamda(v, il.setfailcont(fc), cont.call(v))),
               @cont(goal, il.failcont))

    'parse': (cont, exp, state) ->
      v = il.vari('v')
      oldState = il.vari('state')
      @cont(state, il.clamda(v,
                             il.assign(oldState, il.state),
                             il.setstate(v),
                             @cont(exp, il.clamda(v, il.setstate(oldState), cont.call(v)))))
    'parsetext': (cont, exp, text) ->
      v = il.vari('v')
      oldState = il.vari('state')
      @cont(text, il.clamda(v,
                             il.assign(oldState, il.state),
                             il.setstate(il.array(v, 0)),
                             @cont(exp, il.clamda(v, il.setstate(oldState), cont.call(v)))))
    'setstate': (cont, state) ->
      v = il.vari('v')
      @cont(state, il.clamda(v, il.setstate(v), cont.call(v)))
    'settext': (cont, text) ->
      v = il.vari('v')
      @cont(text, il.clamda(v, il.setstate(il.array(v, 0)), cont.call(v)))
    'getstate': (cont) -> cont.call(il.state)
    'gettext': (cont) -> cont.call(il.index(il.state, 0))
    'getpos': (cont) -> cont.call(il.index(il.state, 1))
    'eoi': (cont) ->
      il.begin(il.listassign(data, pos, il.state)
               il.if_(il.ge(pos,il.length(data)), cont.call(true), il.failcont.call(v)))
    'boi': (cont) -> il.if_(il.eq(il.index(il.state, 1), 0), cont.call(true), il.failcont.call(v))
    # eol: end of line text[pos] in "\r\n"
    'eol': (cont) ->
      il.begin(
                il.listassign(data, pos, il.state),
                il.if_(il.ge(pos, il.length(data.length), cont.call(true),
                             il.if_(il.in(text[pos], il.string("\r\n")), cont.call(true),
                                    il.failcont.call(v)))))
    # eol: end of line text[pos] in "\r\n"
    'eol': (cont) ->
      il.begin(
                il.if_(il.eq(il.index(il.state, 1), 0), cont.call(true),
                             il.if_(il.in(il.index(il.index(il.state, 0), il.sub(il.index(il.state, 1), 1)), il.string("\r\n")),
                                    cont.call(true),
                                    il.failcont.call(v))))

    'step': (cont, n) ->
      @cont(n, il.clamda(v,
        il.listassign(text, pos, il.state),
        il.augassign(pos, v),
        il.setstate(il.array(text, pos)),
        cont.call(pos)))
    # lefttext: return left text
    'lefttext': (cont) -> cont(il.slice(il.index(il.state, 0), il.index(il.state, 1)))
    # subtext: return text[start...start+length]
    'subtext': (solver, cont, length, start) ->
       il.begin(
        il.listassign(text, pos,il.state),
        il.assign(start, il.or_(il.ne(start, null), pos)),
        il.assign(length, il.or_(il.ne(length, null), il.length(pos))),
        cont.call(il.slice(start, il.add(start, length))))

    # nextchar: text[pos]
    'nextchar': (cont) ->
      text = il.vari('text')
      pos = il.vari('pos')
      il.begin(
          il.listassign(text, pos, il.state),
          cont.call(il.index(text, pos)))
    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'follow': (cont, item) ->
      state = il.vari('state')
      il.let_(
         [state, il.state],
         @cont(item, il.clamda(v,
           il.setstate(state),
           cont.call(v))))

    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'notfollow': (cont, item) ->
      state = il.vari('state')
      fc = il.vari('fc')
      il.let_(
         [fc, il.failcont,
          state, il.state],
         il.setfailcont(cont),
         @cont(item, il.clamda(v,
           il.setstate(state),
           fc.call(v))))
    # ##### may, lazymay, greedymay
    # may: aka optional
    'may': (cont, exp) ->
      il.begin(
        il.appendFailcont(cont),
        @cont(exp, cont))
    # lazymay: lazy optional
    'lazymay': (cont, exp) ->
      il.let_([fc, il.failcont],
        il.setfailcont(il.clamda(v,
          il.setfailcont(fc),
          @cont(exp, cont))),
        cont.call(v))
     # greedymay: greedy optional
    'greedymay': (cont, exp) ->
      il.let_([fc, il.failcont],
         il.setfailcont(il.clamda(v,
           il.setfailcont(fc),
           cont.call(v))),
         @cont(exp, il.clamda(v,
                    il.setfailcont(fc),
                    cont.call(v))))
    'any': (cont, exp) ->
      il.begin(
        il.assign(anyCont, il.clamda(v,
        il.let_([fc, il.failcont,
                 trail, il.trail,
                 state, il.state],
          il.settrail(il.newTrail),
          il.setfailcont(il.clamda(v,
            il.undotrail,
            il.settrail(trail),
            il.setstate(state),
            il.setfailcont(fc),
            cont.call(v)))
          @cont(exp, anyCont))))
        anyCont.call(null))
    'lazyany': (cont, exp) ->
      il.begin(
        il.assign(anyCont, il.clamda(v,
          il.setfailcont, anyFcont),
          cont.call(v)),
        il.assign(anyFcont, il.clamda(v,
           il.setfailcont(fc),
           @cont(exp, anyCont))),
        il.assign(fc, solver.failcont),
        anyCont.call(v))
    'greedyany': (cont, exp) ->
        il.begin(
          il.assign(anyCont, il.clamda(v, @cont(exp, anyCont)))
          il.assign(fc, il.failcont;
          il.setfailcont(il.clamda(v, il.setfailcont(fc), cont.call(v)))
          anyCont.call(v)))
    # char: match one char  <br/>
    #  if x is char or bound to char, then match that given char with next<br/>
    #  else match with next char, and bound x to it.
    'xxxchar': (cont, item) ->
      data = il.vari('data')
      pos = il.vari('pos')
      x = il.vari('x')
      c = il.vari('c')
      v = il.vari('v')
      @cont(item, il.clamda(v,
          il.listassign(data, pos, il.state),
          il.if_(il.gt(pos, il.length(data)), il.return(il.failcont.call(v))),
          il.assign(x, il.deref(v)),
          il.assign(c, il.index(data, pos)),
          il.iff(il.instanceof(x, il.symbol('Var')),
                 il.begin(
                   il.bind(x, c),
                   il.setstate(il.array(data, il.add(pos,1))),
                   cont.call(il.add(pos,1))),
                 il.eq(x,c),
                 il.begin(
                   il.setstate(il.array(data, il.add(pos,1))),
                   cont.call(il.add(pos,1))),
                   il.attr(il.symbol('_'), il.symbol('isString')).call(x),
                 il.if_(il.eq(il.length(x), 1),il.failcont.call(v),
                        il.throw(il.new(il.symbol('ExpressionError').call(x)))),
                 il.throw(il.new(il.symbol('TypeError').call(x))))))

    # char: match one char  <br/>
    #  if x is char or bound to char, then match that given char with next<br/>
    #  else match with next char, and bound x to it.
    'char': (cont, item) ->
      v = il.vari('v')
      @cont(item, il.clamda(v, cont.call(il.char(il.solver, v))))


  Compiler = @
  for name, vop of il
    try instance = vop?()
    catch e then continue
    if instance instanceof il.VirtualOperation and name not in il.excludes
      do (name=name, vop=vop) -> Compiler::specials['vop_'+name] = (cont, args...) ->
        compiler = @
        length = args.length
        params = (il.vari('a'+i) for i in [0...length])
        cont = cont.call(vop(params...))
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
      else if _.isObject(exp) then JSON.stringify(exp)
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
          cont = @quasiquote(e, il.clamda(v, il.assign(quasilist, il.concat(quasilist, v)), cont))
        else
          cont = @quasiquote(e, il.clamda(v, il.push(quasilist, v), cont))
      il.begin( il.assign(quasilist, il.list(head)),
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
