# ##dao
_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("./interlang")

hasOwnProperty = Object::hasOwnProperty

exports.solve = (exp, path) ->
  path = process.cwd()+'/lib/compiled.js'
  try fs.unlinkSync(path)
  catch e then null
  compile(exp, path)
  delete require.cache[require.resolve(path)]
  compiled = require(path)
  compiled.main()

compile = (exp, path) ->
  compiler = new Compiler()
  code = compiler.compile(exp) + "\n//exports.main();"
  code = beautify(code, { indent_size: 2})
  fd = fs.openSync(path, 'w')
  fs.writeSync fd, code
  fs.closeSync fd

# ####class Compiler
# the compiler for dao expression
exports.Compiler = class Compiler
  constructor: () ->
    @nameToVarIndex = {}
    @exits = {}
    @continues = {}
    @protect = (cont) -> cont
    @nameVarMap = {}

  compile: (exp) ->
    @env = env = new CpsEnv(null, {})
    exp = @alpha(exp)
    @env = env
    v = @newconst('v')
    done = @clamda(v, il.throw(il.new(il.symbol('SolverFinish').call(v))))
    exps = [ il.assign(il.uservar('_'), il.require('underscore')),
             il.assign(il.uservar('__slice'), il.attr([], il.symbol('slice'))),
             il.assign(il.uservar('solve'), il.attr(il.require('./core'), il.symbol('solve'))),
             il.assign(il.uservar('parser'), il.require('./parser')),
             il.assign(il.uservar('solvecore'), il.require('./solve')),
             il.assign(il.uservar('SolverFinish'), il.attr(il.uservar('solvecore'), il.symbol('SolverFinish'))),
             il.assign(il.uservar('Solver'), il.attr(il.uservar('solvecore'), il.symbol('Solver'))),
             il.assign(il.uservar('Trail'), il.attr(il.uservar('solvecore'), il.symbol('Trail'))),
             il.assign(il.uservar('Var'), il.attr(il.uservar('solvecore'), il.symbol('Var'))),
             il.assign(il.uservar('DummyVar'), il.attr(il.uservar('solvecore'), il.symbol('DummyVar'))),
             il.assign(il.uservar('solver'), il.new(il.symbol('Solver').call())),
             il.assign(il.uservar('UArray'), il.attr(il.uservar('solvecore'), il.symbol('UArray'))),
             il.assign(il.uservar('UObject'), il.attr(il.uservar('solvecore'), il.symbol('UObject'))),
             il.assign(il.uservar('Cons'), il.attr(il.uservar('solvecore'), il.symbol('Cons'))),
             il.assign(il.state, null),
             il.assign(il.catches, {}),
             il.assign(il.trail, il.newTrail),
             il.assign(il.failcont, done),
             il.assign(il.cutcont, il.failcont),
             il.run(il.transparentuserlamda([], @cont(exp, done)))]
    lamda = il.userlamda([], exps...)
    env = new OptimizationEnv(env, {})
    lamda = @optimize(lamda, env)
    lamda = lamda.jsify(@, env)
    exp = il.assign(il.attr(il.uservar('exports'), il.symbol('main')), lamda)
    exp.toCode(@)

  alphaName: (name) -> @env.alphaName(name)
  alphaMacroParam: (name) -> @env.alphaMacroParam(name)
  uniqueName: (name, index) -> @env.uniqueName(name, index)
  uservar: (name) ->
    map = @nameVarMap
    v = map[name]
    if v then v
    else map[name] = v = il.uservar(name); v
  userconst: (name) ->
    map = @nameVarMap
    v = map[name]
    if v then v
    else map[name] = v = il.uservar(name); v.isConst = true; v
  newvar: (v) -> if _.isString(v) then @env.newvar(il.internalvar(v)) else @env.newvar(v)
  newconst: (v) -> if _.isString(v) then @env.newconst(il.internalvar(v)) else @env.newconst(v)
  getvar: (v) -> if _.isString(v) then @env.getvar(il.uservar(v)) else @env.getvar(v)
  lookup: (v) -> if _.isString(v) then @env.lookup(il.uservar(v)) else @env.lookup(v)
  pushEnv: () -> @env = @env.extend()
  popEnv: () -> @env = @env.outer

  clamda: (v, body...) -> @globalCont = cont = il.clamda(v, body...); cont

  # alpha convert
  alpha: (exp) ->
    if _.isString(exp) then return @alphaName(exp)
    if not _.isArray(exp) then return exp
    length = exp.length
    if length is 0 then return exp
    if length is 1 then exp
    head = exp[0]
    if not _.isString(head) then return exp
    if hasOwnProperty.call(@specials, head)
      if hasOwnProperty.call(@specialsAlpha, head) then return @specialsAlpha[head].call(@, head, exp[1...]...)
      else result = [head]; (for i in [1...length] then result.push(@alpha(exp[i]))); result
    else return exp

  # compile to continuation
  cont: (exp, cont) ->
    if _.isString(exp) then return cont.call(@uservar(exp))
    if not _.isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not _.isString(head) then return cont.call(exp)
    if hasOwnProperty.call(@specials, head) then @specials[head].call(@, cont, exp[1...]...)
    else cont.call(exp)


  specials:
    "quote": (cont, exp) -> cont.call(exp)
    "eval": (cont, exp, path) ->
      v = @newconst('v')
      p = @newconst('path')
      @cont(exp, @clamda(v, @cont(path, @clamda(p, cont.call(il.evalexpr(v, p))))))
    'string': (cont, exp) -> cont.call(exp)
    "begin": (cont, exps...) -> @expsCont(exps, cont)
    "nonlocal": (cont, names...) ->
       il.begin(il.nonlocal((@uservar(name) for name in names)), cont.call(null))
    "variable": (cont, vars...) ->
      for name in vars
        v = @uservar(name)
        delete v.isConst
      cont.call(null)
    "uniquevar": (cont, name) -> cont.call(@uservar(name))
    "uniqueconst": (cont, name) -> cont.call(@userconst(name))

    "assign": (cont, left, exp) ->  @leftValueCont(cont, "assign", left, exp)
    "augment-assign": (cont, op, left, exp) ->  @leftValueCont(cont, "augment-assign", left, exp, op)
    'inc': (cont, item) -> @leftValueCont(cont, "inc", item)
    'suffixinc': (cont, item) -> @leftValueCont(cont, "suffixinc", item)
    'dec': (cont, item) ->  @leftValueCont(cont, "dec", item)
    'suffixdec': (cont, item) ->  @leftValueCont(cont, "suffixdec", item)
    'incp': (cont, item) -> @leftValueCont(cont, "incp", item)
    'suffixincp': (cont, item) -> @leftValueCont(cont, "suffixincp", item)
    'decp': (cont, item) ->  @leftValueCont(cont, "decp", item)
    'suffixdecp': (cont, item) ->  @leftValueCont(cont, "suffixdecp", item)

    "if": (cont, test, then_, else_) ->
      v = @newconst('v')
      @cont(test, @clamda(v, il.if_(v, @cont(then_, cont), @cont(else_, cont))))

    "switch": (cont, test, clauses, else_) ->
      v = @newconst('v')
      clauses = for clause in clauses
        values = clause[0]; act = clause[1]
        values = for value in values then il.lamda([], @cont(value, il.idcont)).call()
        act = @cont(act, cont)
        [values, act]
      @cont(test, @clamda(v, il.switch_(v, clauses, @cont(else_, cont))))

    "jsfun": (cont, func) ->
      f = il.jsfun(func)
      f._effect = @_effect
      cont.call(f)

    "direct": (cont, exp) ->
      il.begin(exp, cont.call())

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
      @pushEnv()
      params = (@uservar(p) for p in params)
      globalCont = @globalCont
      @globalCont = il.idcont
      cont = cont.call(il.userlamda(params, @expsCont(body, il.idcont)))
      @globalCont = globalCont
      @popEnv()
      cont

    "macro": (cont, params, body...) ->
      @pushEnv()
      params1 = (@uservar(p) for p in params)
      globalCont = @globalCont
      @globalCont = il.idcont
      cont = cont.call(il.lamda(params1, @expsCont(body, il.idcont)))
      @globalCont = globalCont
      @popEnv()
      cont

    "evalarg": (cont, name) -> cont.call(@uservar(name).call())

    "array": (cont, args...) ->
      compiler = @
      length = args.length
      xs = (@newconst('x'+i) for i in [0...length])
      cont = cont.call(il.array(xs))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(xs[i], cont))
      cont

    "uarray": (cont, args...) ->
      compiler = @
      length = args.length
      xs = (@newconst('x'+i) for i in [0...length])
      cont = cont.call(il.uarray(xs))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(xs[i], cont))
      cont

    "makeobject": (cont, args...) ->
      compiler = @
      length = args.length
      obj = @newconst('object1')
      xs = (@newconst('x'+i) for i in [0...length])
      cont = il.begin(il.assign(obj, {}), il.setobject(obj, xs), cont.call(obj))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(xs[i], cont))
      cont

    "uobject": (cont, args...) ->
      compiler = @
      length = args.length
      obj = @newconst('object1')
      uobj = @newconst('uobject1')
      xs = (@newconst('x'+i) for i in [0...length])
      cont = il.begin(il.assign(obj, {}), il.setobject(obj, xs), il.assign(uobj, il.uobject(obj)), cont.call(uobj))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(xs[i], cont))
      cont

    "cons": (cont, head, tail) ->
      v = @newconst('v'); v2 = @newconst('v')
      @cont(head, @clamda(v, @cont(tail, @clamda(v1, cont.call(il.cons(v, v1))))))

    "funcall": (cont, caller, args...) ->
      compiler = @
      f = @newconst('func')
      length = args.length
      params = (@newconst('arg'+i) for i in [0...length])
      cont = cont.call(f.apply(params))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(params[i], cont))
      @cont(caller, @clamda(f, cont))

    "macall": (cont, caller, args...) ->
      compiler = @
      f = @newconst('func')
      length = args.length
      params = (@newconst('arg'+i) for i in [0...length])
      cont = f.apply(params)
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          globalCont = compiler.globalCont
          compiler.globalCont = il.idcont
          body = compiler.cont(args[i], il.idcont)
          compiler.globalCont = globalCont
          compiler.clamda(params[i], cont).call(il.lamda([], body))
      @cont(caller, @clamda(f, cont))

    "for": (cont, init, test, step, body...) ->
      init = il.lamda([], compiler.cont(init, il.idcont)).call()
      test = il.lamda([], compiler.cont(test, il.idcont)).call()
      step = il.lamda([], compiler.cont(step, il.idcont)).call()
      body = compiler.expsCont(body, il.idcont)
      il.begin(il.for_(init, test, step, body), cont.call(null))

    "forin": (cont, vari, container, body...) ->
      vari = @getvar(vari)
      container = il.lamda([], compiler.cont(container, il.idcont)).call()
      body = compiler.expsCont(body, il.idcont)
      il.begin(il.forin(vari, container), cont.call(null))

    "forof": (cont, vari, container, body...) ->
      vari = @getvar(vari)
      container = il.lamda([], compiler.cont(container, il.idcont)).call()
      body = compiler.expsCont(body, il.idcont)
      il.begin(il.forof(vari, container), cont.call(null))

    "try": (cont, test, catches, final) ->
      test = il.lamda([], compiler.cont(test, il.idcont)).call()
      clauses = []
      for clause in catches
        caluses.push([@.getvar(caluse[0]), compiler.cont(clause[1], il.idcont)])
      final = compiler.cont(final, il.idcont)
      il.begin(il.try_(test, clauses, final), cont.call(null))

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
      exits.push(@globalCont)
      defaultExits = @exits[''] ?= []  # if no label, go here
      defaultExits.push(cont)
      continues = @continues[label] ?= []
      f = @newconst(il.blockvar('block'+label))
      f.isRecursive = true
      fun = il.blocklamda(null)
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
      il.begin(il.assign(f, fun), f.call())

    # break a block
    'break': (cont, label, value) ->
      label = label[1]
      exits = @exits[label]
      if not exits or exits==[] then throw new  Error(label)
      exitCont = exits[exits.length-1]
      globalCont = @globalCont
      cont = @cont(value, @protect(exitCont))
      @globalCont = globalCont
      cont

    # continue a block
    'continue': (cont, label) ->
      label = label[1]
      continues = @continues[label]
      if not continues or continues==[] then throw new  Error(label)
      continueCont = continues[continues.length-1]
      @protect(continueCont).call()

    # aka. lisp style catch/throw
    'catch': (cont, tag, forms...) ->
      v = @newconst('v'); v2 = @newconst('v')
      temp1 = @newconst('temp'); temp2 = @newconst('temp')
      @cont(tag, @clamda(v, il.assign(temp1, v),
                            il.pushCatch(temp1, cont),
                            @expsCont(forms, @clamda(v2, il.assign(temp2, v2),
                                                      il.popCatch(temp1),
                                                      cont.call(temp2)))))

    # aka lisp style throw
    "throw": (cont, tag, form) ->
      v = @newconst('v'); v2 = @newconst('v'); temp = @newconst('temp'); temp2 = @newconst('temp')
      @cont(tag, @clamda(v, il.assign(temp, v),
                            @cont(form, @clamda(v2, il.assign(temp2, v2),
                                                 @protect(il.findCatch(temp)).call(temp2)))))

    # aka. lisp's unwind-protect
    'unwind-protect': (cont, form, cleanup...) ->
      oldprotect = @protect
      v1 = @newconst('v'); v2 = @newconst('v'); temp = @newconst('temp'); temp2 = @newconst('temp')
      compiler = @
      @protect = (cont) -> compiler.clamda(v1, il.assign(temp, v1),
                                     compiler.expsCont(cleanup, compiler.clamda(v2, v2,
                                          oldprotect(cont).call(temp))))
      result = @cont(form,  compiler.clamda(v1, il.assign(temp, v1),
                              @expsCont(cleanup, @clamda(v2, v2,
                                    cont.call(temp)))))
      @protect = oldprotect
      result

    # aka. lisp's call/cc
    # callcc(someFunction(kont) -> body)
    #current continuation @cont can be captured in someFunction
    'callcc': (cont, fun) ->
      v = @newconst('v')
      @cont(fun, @clamda(v, cont.call(v.call(cont, cont))))

    # aka. lisp's call/fc
    # callfc(someFunction(kont) -> body)
    #current continuation @cont can be captured in someFunction
    'callfc': (cont, fun) ->
      v = @newconst('v')
      @cont(fun, @clamda(v, cont.call(v.call(il.failcont, cont))))

    'logicvar': (cont, name) -> cont.call(il.newLogicVar(name))
    'dummy': (cont, name) -> cont.call(il.newDummyVar(name))
    'unify': (cont, x, y) ->
      x1 = @newconst('x'); y1 = @newconst('y')
      @cont(x, @clamda(x1, @cont(y, @clamda(y1,
          il.if_(il.unify(x1, y1), cont.call(true),
             il.failcont.call(false))))))
    'notunify': (cont, x, y) ->
      x1 = @newconst('x'); y1 = @newconst('y')
      @cont(x, @clamda(x1, @cont(y, @clamda(y1,
          il.if_(il.unify(x, y), il.failcont.call(false),
             cont.call(true))))))
    # evaluate @exp and bind it to vari
    'is': (cont, vari, exp) ->
      v = @newconst('v')
      @cont(exp, @clamda(v, il.bind(vari, v), cont.call(true)))
    'bind': (cont, vari, term) -> il.begin(il.bind(vari, il.deref(term)), cont.call(true))
    'getvalue': (cont, term) -> cont.call(il.getvalue(@interlang(term)))
    'succeed': (cont) -> cont.call(true)
    'fail': (cont) -> il.failcont.call(false)

    # x.push(y), when backtracking here, x.pop()
    'pushp': (cont, list, value) ->
      list1 = @newconst('list')
      value1 = @newconst('value')
      list2 = @newconst('list')
      value2 = @newconst('value')
      fc = @newconst('fc')
      v = @newconst('v')
      @cont(list, @clamda(list1,
          il.assign(list2, list1),
          @cont(value, @clamda(value1,
            il.assign(value2, value1),
            il.assign(fc, il.failcont),
            il.setfailcont(il.clamda(v, v, il.pop(list2), fc.call(value2)))
            il.push(list2, value2),
            cont.call(value2)))))

    'orp': (cont, x, y) ->
      v = @newconst('v')
      trail = @newconst('trail')
      state = @newconst('state')
      fc = @newconst('fc')
      il.begin(il.assign(trail, il.trail),
               il.assign(state, il.state),
               il.assign(fc, il.failcont),
               il.settrail(il.newTrail),
               il.setfailcont(il.clamda(v,
                   v,
                   il.undotrail(il.trail),
                   il.settrail(trail),
                   il.setstate(state),
                   il.setfailcont(fc),
                   @cont(y, cont))),
           @cont(x, cont))

    'ifp': (cont, test, action) ->
      #if -> Then; _Else :- If, !, Then.<br/>
      #If -> _Then; Else :- !, Else.<br/>
      #If -> Then :- If, !, Then
      v = @newconst('v')
      fc = @newconst('fc')
      il.begin(il.assign(fc, il.failcont),
        @cont(test, @clamda(v,
          v,
          il.setfailcont(fc),
          @cont(action, cont))))

    #like in prolog, failure as negation.
    'notp': (cont, goal) ->
      v = @newconst('v')
      v1 = @newconst('v')
      trail = @newconst('trail')
      state = @newconst('state')
      fc = @newconst('fc')
      il.begin(il.assign(trail, il.trail),
               il.assign(fc, il.failcont),
               il.assign(state, il.state),
               il.settrail(il.newTrail),
               il.setfailcont(il.clamda(v,
                  il.assign(v1, v),
                  il.undotrail(il.trail),
                  il.settrail(trail),
                  il.setstate(state),
                  il.setfailcont(fc),
                  cont.call(v1))),
               @cont(goal, fc))
    'repeat': (cont) -> il.begin(il.setfailcont(cont), cont.call(null))
    #  make the goal cutable
    'cutable': (cont, goal) ->
      cc = @newconst('cutcont')
      v = @newconst('v')
      v1 = @newconst('v')
      il.begin(il.assign(cc, il.cutcont),
               il.assign(il.cutcont, il.failcont),
               @cont(goal, @clamda(v, il.assign(v1, v), il.setcutcont(cc), cont.call(v1))))
    # prolog's cut, aka "!"
    'cut': (cont) -> il.begin(il.setfailcont(il.cutcont), cont.call(null))
    # find all solution to the goal @exp in prolog
    'findall': (cont, goal, result, template) ->
      fc = @newconst('fc')
      v = @newconst('v')
      v1 = @newconst('v')
      if not result?
        il.begin(il.assign(fc, il.failcont),
                il.setfailcont(il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))),
                @cont(goal, il.failcont))
      else
        v2 = @newconst('v')
        result1 = @newconst('result')
        il.begin(
          il.assign(result1, []),
          il.assign(fc, il.failcont),
          il.setfailcont(il.clamda(v2, il.assign(v1, v2),
                                   il.if_(il.unify(@interlang(result), result1),
                                          il.begin(il.setfailcont(fc), cont.call(null)),
                                          fc.call(v1)))),
          @cont(goal, @clamda(v, il.assign(v1, v),
            il.push(result1, il.getvalue(@interlang(template))),
            il.failcont.call(v1))))

    # find only one solution to the @goal
    'once': (cont, goal) ->
      fc = @newconst('fc')
      v = @newconst('v')
      v1 = @newconst('v')
      il.begin(il.assign(fc, il.failcont),
        @cont(goal, @clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))))

    'parse': (cont, exp, state) ->
      v = @newconst('v')
      v1 = @newconst('v')
#      fc = @newconst('fc')
      oldState = @newconst('state')
      @cont(state, @clamda(v, il.assign(oldState, il.state),
#                               il.assign(fc, il.failcont),
#                               il.setfailcont(il.clamda(v, v, il.setstate(oldState), fc.call(false))),
                               il.setstate(v),
                               @cont(exp, @clamda(v, il.assign(v1, v), il.setstate(oldState), cont.call(v1)))))
    'parsetext': (cont, exp, text) ->
      v = @newconst('v')
      v1 = @newconst('v')
#      fc = @newconst('fc')
      oldState = @newconst('state')
      @cont(text, @clamda(v,
                          il.begin(il.assign(oldState, il.state),
#                             il.assign(fc, il.failcont),
#                             il.setfailcont(il.clamda(v, v, il.setstate(oldState), fc.call(false))),
                             il.setstate(il.array(v, 0)),
                             @cont(exp, @clamda(v, il.assign(v1, v), il.setstate(oldState), cont.call(v1))))))
    'setstate': (cont, state) ->
      v = @newconst('v')
      @cont(state, @clamda(v, il.setstate(v), cont.call(true)))
    'settext': (cont, text) ->
      v = @newconst('v')
      @cont(text, @clamda(v, il.setstate(il.array(v, 0)), cont.call(true)))
    'setpos': (cont, pos) ->
      v = @newconst('v')
      @cont(pos, @clamda(v, il.assign(il.index(il.state, 1), v), cont.call(true)))
    'getstate': (cont) -> cont.call(il.state)
    'gettext': (cont) -> cont.call(il.index(il.state, 0))
    'getpos': (cont) -> cont.call(il.index(il.state, 1))
    'eoi': (cont) ->
      data = @newconst('data'); pos = @newconst('pos')
      il.begin(il.listassign(data, pos, il.state),
               il.if_(il.ge(pos, il.length(data)), cont.call(true), il.failcont.call(false)))
    'boi': (cont) -> il.if_(il.eq(il.index(il.state, 1), 0), cont.call(true), il.failcont.call(false))
    # eol: end of line text[pos] in "\r\n"
    'eol': (cont) ->
      text = @newconst('text'); pos = @newconst('pos');  c = @newconst('c')
      il.begin(
                il.listassign(text, pos, il.state),
                il.if_(il.ge(pos, il.length(text)), cont.call(true),
                     il.begin(
                       il.assign(c, il.index(text, pos, 1)),
                       il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                            cont.call(true),
                            il.failcont.call(false)))))
    'bol': (cont) ->
      text = @newconst('text'); pos = @newconst('pos');  c = @newconst('c')
      il.begin(
                il.listassign(text, pos, il.state),
                il.if_(il.eq(pos, 0), cont.call(true),
                         il.begin(
                             il.assign(c, il.index(text, il.sub(pos, 1))),
                             il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                                    cont.call(true),
                                    il.failcont.call(false)))))

    'step': (cont, n) ->
      v = @newconst('v'); text = @newconst('text'); pos = @newconst('pos'); pos1 = @newconst('pos')
      @cont(n, @clamda(v,
        il.listassign(text, pos, il.state),
        il.assign(pos1, il.add(pos, v)),
        il.setstate(il.array(text, pos1)),
        cont.call(pos1)))
    # lefttext: return left text
    'lefttext': (cont) -> cont.call(il.slice(il.index(il.state, 0), il.index(il.state, 1)))
    # subtext: return text[start...start+length]
    'subtext': (cont, length, start) ->
      text = @newconst('text'); pos = @newconst('pos')
      start1 = @newconst('start'); length1 = @newconst('length')
      start2 = @newconst('start'); length2 = @newconst('length')
      start3 = @newconst('start'); length3 = @newconst('length')
      @cont(length, @clamda(length1,
        il.assign(length2, length1),
        @cont(start, @clamda(start1,
          il.assign(start2, start1),
          il.listassign(text, pos, il.state),
          il.begin(il.assign(start3, il.if_(il.ne(start2, null), start2, pos)),
                   il.assign(length3, il.if_(il.ne(length2, null), length2, il.length(text))),
                   cont.call(il.slice(text, start3, il.add(start3, length3))))))))

    # nextchar: text[pos]
    'nextchar': (cont) ->
      text = @newconst('text')
      pos = @newconst('pos')
      il.begin(
          il.listassign(text, pos, il.state),
          cont.call(il.index(text, pos)))
    # ##### may, lazymay, greedymay
    # may: aka optional
    'may': (cont, exp) ->
      il.begin(
        il.appendFailcont(cont),
        @cont(exp, cont))
    # lazymay: lazy optional
    'lazymay': (cont, exp) ->
      fc = @newconst('fc')
      v = @newconst('v')
      il.begin(il.assign(fc, il.failcont),
        il.setfailcont(il.clamda(v,
          v,
          il.setfailcont(fc),
          @cont(exp, cont))),
        cont.call(null))
     # greedymay: greedy optional
    'greedymay': (cont, exp) ->
      fc = @newconst('fc')
      v = @newconst('v')
      v1 = @newconst('v')
      v2 = @newconst('v')
      il.begin(il.assign(fc, il.failcont),
         il.setfailcont(il.clamda(v,
           il.assign(v1, v),
           il.setfailcont(fc),
           cont.call(v1))),
         @cont(exp, @clamda(v,il.assign(v2, v),
                    il.setfailcont(fc),
                    cont.call(v2))))
    'any': (cont, exp) ->
      fc = @newconst('fc')
      trail = @newconst('trail')
      state = @newconst('state')
      anyCont = @newconst('anyCont')
      anyCont.isRecursive = true
      v = @newconst('v')
      v1 = @newconst('v')
      il.begin(
        il.assign(anyCont, il.recclamda(v,
                 il.assign(fc, il.failcont),
                 il.assign(trail, il.trail),
                 il.assign(state, il.state),
                 il.settrail(il.newTrail),
                 il.setfailcont(il.clamda(v,
                   il.assign(v1, v),
                   il.undotrail(il.trail),
                   il.settrail(trail),
                   il.setstate(state),
                   il.setfailcont(fc),
                   cont.call(v1)))
                 @cont(exp, anyCont)))
         anyCont.call(null))

    'lazyany': (cont, exp) ->
      fc = @newconst('fc')
      trail = @newconst('trail')
      v = @newconst('v')
      anyCont = @newconst('anyCont')
      anyFcont = @newconst('anyFcont')
      anyCont.isRecursive = true
      anyFcont.isRecursive = true
      il.begin(
        il.local(trail),
        il.assign(anyCont, il.recclamda(v,
          il.nonlocal(trail),
          il.assign(trail, il.trail),
          il.settrail(il.newTrail),
          il.setfailcont(anyFcont),
          cont.call(null))),
        il.assign(anyFcont, il.recclamda(v,
           il.undotrail(il.trail),
           il.settrail(trail),
           il.setfailcont(fc),
           @cont(exp, anyCont))),
        il.assign(fc, il.failcont),
        anyCont.call(null))
    'greedyany': (cont, exp) ->
      fc = @newconst('fc')
      anyCont = @newconst('anyCont')
      anyCont.isRecursive = true
      v = @newconst('v')
      v1 = @newconst('v')
      il.begin(
          il.assign(anyCont, il.recclamda(v, @cont(exp, anyCont))),
          il.assign(fc, il.failcont),
          il.setfailcont(il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))),
          anyCont.call(null))
    'parallel': (cont, x, y, checkFunction = (state, baseState) -> state[1] is baseState[1]) ->
      state = @newconst('state')
      right = @newconst('right')
      v = @newconst('v')
      v1 = @newconst('v')
      il.begin(il.assign(state, il.state),
        @cont(x,  @clamda(v,
          v,
          il.assign(right, il.state),
          il.setstate(state),
          @cont(y, @clamda(v, il.assign(v1, v),
                         il.if_(il.fun(checkFunction).call(il.state, right), cont.call(v1),
                            il.failcont.call(v1)))))))
    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'follow': (cont, item) ->
      state = @newconst('state')
      v = @newconst('v')
      v1 = @newconst('v')
      state = @newconst('state')
      il.begin(il.assign(state, il.state),
               @cont(item, @clamda(v, il.assign(v1, v),
                                     il.setstate(state),
                                     cont.call(v))))

    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'notfollow': (cont, item) ->
      state = @newconst('state')
      fc = @newconst('fc')
      v = @newconst('v')
      v1 = @newconst('v')
      il.begin(
              il.assign(fc, il.failcont),
              il.assign(state, il.state),
              il.setfailcont(cont),
              @cont(item, @clamda(v,il.assign(v1, v),
                                     il.setstate(state),
                                     fc.call(v1))))

    # char: match one char  <br/>
    #  if x is char or bound to char, then match that given char with next<br/>
    #  else match with next char, and bound x to it.
    'xxxchar': (cont, item) ->
      data = @newconst('data')
      pos = @newconst('pos')
      x = @newconst('x')
      c = @newconst('c')
      v = @newconst('v')
      @cont(item, @clamda(v,
          il.listassign(data, pos, il.state),
          il.if_(il.gt(pos, il.length(data)), il.return(il.failcont.call(v))),
          il.begin(il.assign(x, il.deref(v)),
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
               il.throw(il.new(il.symbol('TypeError').call(x)))))))

    'spaces': (cont, item) -> cont.call(il.spaces(il.solver))
    'spaces0': (cont, item) -> cont.call(il.spaces0(il.solver))

  Compiler = @
  for name, vop of il
    try instance = vop?()
    catch e then continue
    if instance instanceof il.VirtualOperation and name not in il.excludes
      do (name=name, vop=vop) -> Compiler::specials['vop_'+name] = (cont, args...) ->
        compiler = @
        length = args.length
        params = (@newconst('a'+i) for i in [0...length])
        cont = cont.call(vop(params...))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], compiler.clamda(params[i], cont))
        cont

  for name in ['char', 'followChars', 'notFollowChars', 'charWhen', 'stringWhile', 'stringWhile0',
                'literal', 'followLiteral']
    do (name=name, vop=vop) -> Compiler::specials[name] = (cont, item) ->
      compiler = @
      v = @newconst('v')
      compiler.cont(item, compiler.clamda(v, cont.call(il[name](il.solver, v))))

  for name in [ 'number','quoteString', 'identifier']
    do (name=name, vop=vop) -> Compiler::specials[name] = (cont, item) ->
      cont.call(il[name](il.solver))

  leftValueCont: (cont, task, item, exp, op) ->
    assignExpCont = (item) =>
      v = @newconst('v')
      temp = @newconst('temp')
      switch task
        when 'assign' then return @cont(exp, @clamda(v, il.assign(item, v), cont.call(item)))
        when 'augment-assign'
          return @cont(exp, @clamda(v, il.assign(item, il[op](item, v)), cont.call(item)))
        when 'inc'
          return il.begin(il.assign(item, il.add(item, 1)), cont.call(item))
        when 'dec'
          return il.begin(il.assign(item, il.sub(item, 1)), cont.call(item))
        when 'suffixinc'
          return il.begin(il.assign(temp, item), il.assign(item, il.add(item, 1)), cont.call(temp))
        when 'suffixdec'
          return il.begin(il.assign(temp, item), il.assign(item, il.sub(item, 1)), cont.call(temp))
        when 'incp'
          fc = @newconst('fc')
          return il.begin(il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.sub(item, 1)),fc.call(item))),
                          il.assign(item, il.add(item, 1)),
                          cont.call(item))
        when 'decp'
          fc = @newconst('fc')
          return il.begin(il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.add(item, 1)),fc.call(item))),
                          il.assign(item, il.sub(item, 1)),
                          cont.call(item))
        when 'suffixincp'
          fc = @newconst('fc')
          return il.begin(il.assign(temp, item), il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.sub(item, 1)),fc.call(temp))),
                          il.assign(item, il.add(item, 1)),
                          cont.call(temp))
        when 'suffixdecp'
          fc = @newconst('fc')
          return il.begin(il.assign(temp, item), il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.add(item, 1)),fc.call(temp))),
                          il.assign(item, il.sub(item, 1)),
                          cont.call(temp))
    if  _.isString(item) then return assignExpCont(@uservar(item))
    if not _.isArray(item) then throw new Error "Left value should be an sexpression."
    length = item.length
    if length is 0 then throw new Error "Left value side should not be empty list."
    head = item[0]
    if not _.isString(head) then throw new Error "Keyword should be a string."
    if head is "index"
      object = item[1]; index = item[2]
      obj = @newconst('obj')
      i = @newconst('i')
      @cont(object, il.clamda(obj, @cont(index, il.clamda(i, assignExpCont(il.index(obj, i))))))
    else if head is 'uniquevar' then return assignExpCont(@uservar(item[1]))
    else if head is 'uniqueconst' then return assignExpCont(@userconst(item[1]))
    else throw new Error "Left Value side should be assignable expression."

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw new  exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else
      v = @newconst('v')
      @cont(exps[0], @clamda(v, v, @expsCont(exps[1...], cont)))

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
      quasilist = @newvar('quasilist')
      v = @newconst('v')
      cont = cont.call(quasilist)
      for i in [exp.length-1..1] by -1
        e = exp[i]
        if  _.isArray(e) and e.length>0 and e[0] is "unquote-slice"
          cont = @quasiquote(e, @clamda(v, il.assign(quasilist, il.concat(quasilist, v)), cont))
        else
          cont = @quasiquote(e, @clamda(v, il.push(quasilist, v), cont))
      il.begin( il.assign(quasilist, il.list(head)),
        cont)

  interlang: (term) ->
    if _.isString(term) then return @uservar(term)
    if not _.isArray(term) then return term
    length = term.length
    if length is 0 then return term
    head = term[0]
    if not _.isString(head) then return term
    if head is 'string' then return term[1]
    if head is 'uniquevar' then return @uservar(term)
    if head is 'uniqueconst' then return @userconst(term)
    return term
    # should add stuffs such as 'cons', 'uarray', 'uobject', etc.
#    @specials.hasOwnProperty(head) then return term
    #    @specials[head].call(this, cont, exp[1...]...)

  specialsAlpha:
    'string': (head, exp) -> [head,  exp]
    "begin": (head, exps...) -> result = [head]; (for e in exps then result.push(@alpha(e))); result
    "nonlocal": (head, vars...) ->
      result = [head];
      for name in vars
        result.push(@alphaName(name))
      result
    "variable": (head, vars...) ->
      result = [head]; result.push(@alphaName(name) for name in vars); result
    "assign": (head, left, exp) ->
       [head, @alpha(left), @alpha(exp)]
    "uniquevar": (head, name, index) -> [head, @uniqueName(name, index)]
    "uniqueconst": (head, name, index) -> [head, @uniqueName(name, index)]
    "jsfun": (head, exp) -> [head, exp]
    "direct": (head, exp) -> [head, exp]
    "pure": (head, exp) -> [head, exp]
    "effect": (head, exp) -> [head, exp]
    "io": (head, exp) -> [head, exp]
    "lambda": (head, params, body...) ->
      result = [head]
      @pushEnv()
      result.push(@alphaName(p) for p in params)
      for e in body then result.push(@alpha(e))
      @popEnv()
      result
    "macro": (head, params, body...) ->
      result = [head]
      @pushEnv()
      result.push(@alphaMacroParam(p) for p in params)
      for e in body then result.push(@alpha(e))
      @popEnv()
      result
    "quasiquote": (head, exp) -> [head, @alpha(exp)]
    "unquote": (head, exp) ->  [head, @alpha(exp)]
    "unquote-slice": (head, exp) -> [head, @alpha(exp)]
    'block': (head, label, body...) ->
      result = [head, label]
      for e in body then result.push(@alpha(e))
      result
    'break': (head, label, value) -> [head, label, @alpha(value)]
    'continue': (head, label) -> [head, label]
    'logicvar': (head, name) -> [head, name]
    'dummy': (head, name) -> [head, name]

  optimize: (exp, env) ->
    expOptimize = exp?.optimize
    if expOptimize then expOptimize.call(exp, env, @)
    else exp

  toCode: (exp) ->
    exptoCode = exp?.toCode
    if exptoCode then exptoCode.call(exp, @)
    else if typeof exp is 'function' then exp.toString()
    else  JSON.stringify(exp)
#      if exp is undefined then 'undefined'
#      else if exp is null then 'null'
#      else if _.isNumber(exp) then exp.toString()
#      else if _.isString(exp) then JSON.stringify(exp)
#      else if exp is true then "true"
#      else if exp is false then "false"
#      else if _.isArray(exp) then JSON.stringify(exp)
#      else if typeof exp is 'function' then exp.toString()
#      else if _.isObject(exp) then JSON.stringify(exp)
#      else exp.toString()

class Env

exports.Env = class Env
  constructor: (@outer, @bindings) ->
  extend: (bindings={}) -> new @constructor(@, bindings)
  lookup: (vari) ->
    bindings = @bindings
    if bindings.hasOwnProperty(vari) then return bindings[vari]
    else
      outer = @outer
      if outer then outer.lookup(vari) else vari

class CpsEnv extends Env
  constructor: (@outer, @bindings) ->
    if @outer then @indexMap = @outer.indexMap; @vars = @outer.vars
    else @indexMap = {}; @vars = {}

  newvar: (vari) ->
    vars = @vars
    index = @indexMap[vari.name] or 2
    while 1
      if not hasOwnProperty.call(vars, vari)
        vars[vari] = vari; @indexMap[vari.name] = index; return vari
      vari = new vari.constructor(vari.name, (index++).toString())

  alphaNewName: (name) ->
    vars = @vars
    index = @indexMap[name] or 2
    newName = name
    while 1
      if not hasOwnProperty.call(vars, newName)
        vars[name] = newName; @indexMap[name] = index; return newName
      newName = name+index

  newconst: (vari) ->
    vars = @vars
    index = @indexMap[vari.name] or 2
    while 1
      if not hasOwnProperty.call(vars, vari)
        vars[vari] = vari
        @indexMap[vari.name] = index
        vari.isConst = true
        return vari
      vari = new vari.constructor(vari.name, (index++).toString())

  lookup: (vari) ->
    bindings = @bindings
    if hasOwnProperty.call(bindings, vari) then return bindings[vari]
    else
      outer = @outer
      if outer then outer.lookup(vari)
      else throw new VarLookupError(vari)

  getvar: (vari) ->
    try @lookup(vari)
    catch e
      if e instanceof VarLookupError
        @bindings[vari] = v = @newconst(vari)
        v

  alphaName: (name) ->
    try name = @lookup(name)
    catch e
      if e instanceof VarLookupError
        @bindings[name] = name = @alphaNewName(name)
        name

  alphaMacroParam: (name) ->
    try name = @lookup(name)
    catch e
      if e instanceof VarLookupError
        @bindings[name] = result = ['evalarg', @alphaNewName(name)]
        result

  uniqueName: (name, index) ->
    uniquename = '@'+name+index
    try @lookup(uniquename)
    catch e
      if e instanceof VarLookupError
        @bindings[uniquename] = v = @alphaNewName(name)
        v

exports.OptimizationEnv = class OptimizationEnv extends CpsEnv
  constructor: (@outer, bindings, @lamda) ->
    if bindings then @bindings = bindings
    else @bindings = outer.bindings
    if @outer then @indexMap = @outer.indexMap; @vars = @outer.vars
    else @indexMap = {}; @vars = {}
    if lamda instanceof il.UserLamda then @userlamda = lamda
    else while outer
        if outer.userlamda then @userlamda = outer.userlamda; return
        outer = outer.outer

  extendBindings: (bindings, lamda) -> new OptimizationEnv(@, bindings, lamda)
  lookup: (vari) ->
    bindings = @bindings
    if bindings.hasOwnProperty(vari) then return bindings[vari]
    else
      if @isConst
        outer = @outer
        if outer then outer.lookup(vari) else vari
      else vari

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

class VarLookupError
  constructor: (@vari) ->

exports.TypeError = class TypeError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error
