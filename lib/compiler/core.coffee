# ##dao
_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("./interlang")

hasOwnProperty = Object::hasOwnProperty

exports.solve = (exp, path) ->
  path = compile(exp, path)
  delete require.cache[require.resolve(path)]
  compiled = require(path)
  compiled.main()

compile = (exp, path) ->
  compiler = new Compiler()
  code = compiler.compile(exp) + "\n//exports.main();"
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
    @env = new CpsEnv(null, {})
    v = @newvar('v')
    v2 = @newvar('v')
    done = @clamda(v, il.throw(il.new(il.symbol('SolverFinish').call(v))))
    exps = [ il.assign(il.uservar('_'), il.require('underscore')),
             il.assign(il.uservar('__slice'), il.attr([], il.symbol('slice'))),
             il.assign(il.uservar('solve'), il.attr(il.require('f:/daonode/lib/compiler/core.js'), il.symbol('solve'))),
             il.assign(il.uservar('parser'), il.require('f:/daonode/lib/compiler/parser.js')),
             il.assign(il.uservar('solvecore'), il.require('f:/daonode/lib/compiler/solve.js')),
             il.assign(il.uservar('SolverFinish'), il.attr(il.uservar('solvecore'), il.symbol('SolverFinish'))),
             il.assign(il.uservar('Solver'), il.attr(il.uservar('solvecore'), il.symbol('Solver'))),
             il.assign(il.uservar('Trail'), il.attr(il.uservar('solvecore'), il.symbol('Trail'))),
             il.assign(il.uservar('Var'), il.attr(il.uservar('solvecore'), il.symbol('Var'))),
             il.assign(il.uservar('DummyVar'), il.attr(il.uservar('solvecore'), il.symbol('DummyVar'))),
             il.assign(il.uservar('solver'), il.new(il.symbol('Solver').call())),
             il.assign(il.state, null),
             il.assign(il.catches, {}),
             il.assign(il.trail, il.newTrail),
             il.assign(il.failcont, done),
             il.assign(il.cutcont, il.failcont),
             il.run(il.clamda(v2, @cont(exp, done)))]
    lamda = il.userlamda([], exps...)
    env = new OptimizationEnv(env, {})
    lamda = @optimize(lamda, env)
    lamda = lamda.jsify(@, env)
    exp = il.assign(il.attr(il.uservar('exports'), il.symbol('main')), lamda)
    exp.toCode(@)

  newvar: (v) -> if _.isString(v) then @env.newvar(il.internalvar(v)) else @env.newvar(v)
  getvar: (v) -> if _.isString(v) then @env.getvar(il.uservar(v)) else @env.getvar(v)
  lookup: (v) -> if _.isString(v) then @env.lookup(il.uservar(v)) else @env.lookup(v)
  pushEnv: () -> @env = @env.extend()
  popEnv: () -> @env = @env.outer

  clamda: (v, body...) -> @globalCont = cont = il.clamda(v, body...); cont

  # compile to continuation
  cont: (exp, cont) ->
    if _.isString(exp) then return cont.call(@getvar(exp))
    if not _.isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not _.isString(head) then return cont.call(exp)
    if not @specials.hasOwnProperty(head) then return cont.call(exp)
    @specials[head].call(this, cont, exp[1...]...)

  leftValueCont: (cont, task, item, exp, op) ->
    assignExpCont = (item) =>
      v = @newvar('v')
      temp = @newvar('temp')
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
          fc = @newvar('fc')
          return il.begin(il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.sub(item, 1)),fc.call(item))),
                          il.assign(item, il.add(item, 1)),
                          cont.call(item))
        when 'decp'
          fc = @newvar('fc')
          return il.begin(il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.add(item, 1)),fc.call(item))),
                          il.assign(item, il.sub(item, 1)),
                          cont.call(item))
        when 'suffixincp'
          fc = @newvar('fc')
          return il.begin(il.assign(temp, item), il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.sub(item, 1)),fc.call(temp))),
                          il.assign(item, il.add(item, 1)),
                          cont.call(temp))
        when 'suffixdecp'
          fc = @newvar('fc')
          return il.begin(il.assign(temp, item), il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.add(item, 1)),fc.call(temp))),
                          il.assign(item, il.sub(item, 1)),
                          cont.call(temp))
    if  _.isString(item) then return assignExpCont(@getvar(item))
    if not _.isArray(item) then throw new Error "Left value should be an sexpression."
    length = item.length
    if length is 0 then throw new Error "Left value side should not be empty list."
    head = item[0]
    if not _.isString(head) then throw new Error "Keyword should be a string."
    if head is "index"
      object = item[1]; index = item[2]
      obj = @newvar('obj'); i = @newvar('i'); v = @newvar('v')
      @cont(object, il.clamda(obj, @cont(index, il.clamda(i, assignExpCont(il.index(obj, i))))))
    else throw new Error "Left Value side should be assignable expression."

  specials:
    "quote": (cont, exp) -> cont.call(exp)
    "eval": (cont, exp, path) ->
      v = @newvar('v')
      p = @newvar('path')
      @cont(exp, @clamda(v, @cont(path, @clamda(p, cont.call(il.evalexpr(v, p))))))
    'string': (cont, exp) -> cont.call(exp)
    "begin": (cont, exps...) -> @expsCont(exps, cont)
    "nonlocal": (cont, vars...) ->  il.begin(il.nonlocalvar(vars), cont.call(null))
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
      v = @newvar('v')
      @cont(test, @clamda(v, il.if_(v, @cont(then_, cont), @cont(else_, cont))))

    "switch": (cont, test, clauses, else_) ->
      v = @newvar('v')
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
      params = (@getvar(p) for p in params)
      globalCont = @globalCont
      @globalCont = il.idcont
      cont = cont.call(il.userlamda(params, @expsCont(body, il.idcont)))
      @globalCont = globalCont
      @popEnv()
      cont

    "macro": (cont, params, body...) ->
      @pushEnv()
      params1 = (@getvar(p) for p in params)
      body = (@substMacroArgs(body[i], params) for i in [0...body.length])
      globalCont = @globalCont
      @globalCont = il.idcont
      cont = cont.call(il.lamda(params1, @expsCont(body, il.idcont)))
      @globalCont = globalCont
      @popEnv()
      cont

    "evalarg": (cont, name) -> cont.call(@getvar(name).call())

    "funcall": (cont, caller, args...) ->
      compiler = @
      f = @newvar('func')
      length = args.length
      params = (@newvar('arg'+i) for i in [0...length])
      cont = cont.call(f.apply(params))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(params[i], cont))
      @cont(caller, @clamda(f, cont))

    "macall": (cont, caller, args...) ->
      compiler = @
      f = @newvar('func'); v = @newvar('v')
      length = args.length
      params = (@newvar('arg'+i) for i in [0...length])
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
      f = @newvar(il.blockvar('block'+label))
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
      v = @newvar('v'); v2 = @newvar('v');
      temp1 = @newvar('temp'); temp2 = @newvar('temp')
      @cont(tag, @clamda(v, il.assign(temp1, v),
                            il.pushCatch(temp1, cont),
                            @expsCont(forms, @clamda(v2, il.assign(temp2, v2),
                                                      il.popCatch(temp1),
                                                      cont.call(temp2)))))

    # aka lisp style throw
    "throw": (cont, tag, form) ->
      v = @newvar('v'); v2 = @newvar('v'); temp = @newvar('temp'); temp2 = @newvar('temp')
      @cont(tag, @clamda(v, il.assign(temp, v),
                            @cont(form, @clamda(v2, il.assign(temp2, v2),
                                                 @protect(il.findCatch(temp)).call(temp2)))))

    # aka. lisp's unwind-protect
    'unwind-protect': (cont, form, cleanup...) ->
      oldprotect = @protect
      v1 = @newvar('v'); v2 = @newvar('v'); temp = @newvar('temp'); temp2 = @newvar('temp')
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
      v = @newvar('v')
      @cont(fun, @clamda(v, cont.call(v.call(cont, cont))))

    # aka. lisp's call/fc
    # callfc(someFunction(kont) -> body)
    #current continuation @cont can be captured in someFunction
    'callfc': (cont, fun) ->
      v = @newvar('v')
      @cont(fun, @clamda(v, cont.call(v.call(il.failcont, cont))))

    'logicvar': (cont, name) -> cont.call(il.newLogicVar(name))
    'dummy': (cont, name) -> cont.call(il.newDummyVar(name))
    'unify': (cont, x, y) ->
      x1 = @newvar('x'); y1 = @newvar('y')
      @cont(x, @clamda(x1, @cont(y, @clamda(y1,
          il.if_(il.unify(x1, y1), cont.call(true),
             il.failcont.call(false))))))
    'notunify': (cont, x, y) ->
      x1 = @newvar('x'); y1 = @newvar('y')
      @cont(x, @clamda(x1, @cont(y, @clamda(y1,
          il.if_(il.unify(x, y), il.failcont.call(false),
             cont.call(true))))))
    # evaluate @exp and bind it to vari
    'is': (cont, vari, exp) ->
      v = @newvar('v')
      @cont(exp, @clamda(v, il.bind(vari, v), cont.call(true)))
    'bind': (cont, vari, term) -> il.begin(il.bind(vari, il.deref(term)), cont.call(true))
    'getvalue': (cont, term) -> cont.call(il.getvalue(@interlang(term)))
    'succeed': (cont) -> cont.call(true)
    'fail': (cont) -> il.failcont.call(false)

    # x.push(y), when backtracking here, x.pop()
    'pushp': (cont, list, value) ->
      list1 = @newvar('list')
      value1 = @newvar('value')
      list2 = @newvar('list')
      value2 = @newvar('value')
      fc = @newvar('fc')
      v = @newvar('v')
      @cont(list, @clamda(list1,
          il.assign(list2, list1),
          @cont(value, @clamda(value1,
            il.assign(value2, value1),
            il.assign(fc, il.failcont),
            il.setfailcont(il.clamda(v, v, il.pop(list2), fc.call(value2)))
            il.push(list2, value2),
            cont.call(value2)))))

    'orp': (cont, x, y) ->
      v = @newvar('v')
      trail = @newvar('trail')
      state = @newvar('state')
      fc = @newvar('fc')
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
      v = @newvar('v')
      fc = @newvar('fc')
      il.begin(il.assign(fc, il.failcont),
        @cont(test, @clamda(v,
          v,
          il.setfailcont(fc),
          @cont(action, cont))))

    #like in prolog, failure as negation.
    'notp': (cont, goal) ->
      v = @newvar('v')
      v1 = @newvar('v')
      trail = @newvar('trail')
      state = @newvar('state')
      fc = @newvar('fc')
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
      cc = @newvar('cutcont')
      v = @newvar('v')
      v1 = @newvar('v')
      il.begin(il.assign(cc, il.cutcont),
               il.assign(il.cutcont, il.failcont),
               @cont(goal, @clamda(v, il.assign(v1, v), il.setcutcont(cc), cont.call(v1))))
    # prolog's cut, aka "!"
    'cut': (cont) -> il.begin(il.setfailcont(il.cutcont), cont.call(null))
    # find all solution to the goal @exp in prolog
    'findall': (cont, goal, result, template) ->
      fc = @newvar('fc')
      v = @newvar('v')
      v1 = @newvar('v')
      if not result?
        il.begin(il.assign(fc, il.failcont),
                il.setfailcont(il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))),
                @cont(goal, il.failcont))
      else
        v2 = @newvar('v')
        result1 = @newvar('result')
        il.begin(
          il.assign(result1, []),
          il.assign(fc, il.failcont),
          il.setfailcont(il.clamda(v2, il.assign(v1, v2),
                                   il.if_(il.unify(result, result1), fc.call(v1),
                                       il.begin(il.setfailcont(fc), cont.call(null))))),
          @cont(exp, @clamda(v, il.assign(v1, v),
            il.push(result1, il.getvalue(template)),
            il.failcont.call(v1))))

    # find only one solution to the @goal
    'once': (cont, goal) ->
      fc = @newvar('fc')
      v = @newvar('v')
      v1 = @newvar('v')
      il.begin(il.assign(fc, il.failcont),
        @cont(goal, @clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))))

    'parse': (cont, exp, state) ->
      v = @newvar('v')
      v1 = @newvar('v')
      oldState = @newvar('state')
      @cont(state, @clamda(v, il.assign(oldState, il.state),
                               il.setstate(v),
                               @cont(exp, @clamda(v, il.assign(v1, v), il.setstate(oldState), cont.call(v1)))))
    'parsetext': (cont, exp, text) ->
      v = @newvar('v')
      v1 = @newvar('v')
      oldState = @newvar('state')
      @cont(text, @clamda(v,
                          il.begin(il.assign(oldState, il.state),
                             il.setstate(il.array(v, 0)),
                             @cont(exp, @clamda(v, il.assign(v1, v), il.setstate(oldState), cont.call(v1))))))
    'setstate': (cont, state) ->
      v = @newvar('v')
      @cont(state, @clamda(v, il.setstate(v), cont.call(true)))
    'settext': (cont, text) ->
      v = @newvar('v')
      @cont(text, @clamda(v, il.setstate(il.array(v, 0)), cont.call(true)))
    'setpos': (cont, pos) ->
      v = @newvar('v')
      @cont(pos, @clamda(v, il.assign(il.index(il.state, 1), v), cont.call(true)))
    'getstate': (cont) -> cont.call(il.state)
    'gettext': (cont) -> cont.call(il.index(il.state, 0))
    'getpos': (cont) -> cont.call(il.index(il.state, 1))
    'eoi': (cont) ->
      data = @newvar('data'); pos = @newvar('pos')
      il.begin(il.listassign(data, pos, il.state),
               il.if_(il.ge(pos, il.length(data)), cont.call(true), il.failcont.call(false)))
    'boi': (cont) -> il.if_(il.eq(il.index(il.state, 1), 0), cont.call(true), il.failcont.call(false))
    # eol: end of line text[pos] in "\r\n"
    'eol': (cont) ->
      text = @newvar('text'); pos = @newvar('pos');  c = @newvar('c')
      il.begin(
                il.listassign(text, pos, il.state),
                il.if_(il.ge(pos, il.length(text)), cont.call(true),
                     il.begin(
                       il.assign(c, il.index(text, pos, 1)),
                       il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                            cont.call(true),
                            il.failcont.call(false)))))
    'bol': (cont) ->
      text = @newvar('text'); pos = @newvar('pos');  c = @newvar('c')
      il.begin(
                il.listassign(text, pos, il.state),
                il.if_(il.eq(pos, 0), cont.call(true),
                         il.begin(
                             il.assign(c, il.index(text, il.sub(pos, 1))),
                             il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                                    cont.call(true),
                                    il.failcont.call(false)))))

    'step': (cont, n) ->
      v = @newvar('v'); text = @newvar('text'); pos = @newvar('pos');
      @cont(n, @clamda(v,
        il.listassign(text, pos, il.state),
#          il.assign(pos, pos),
        il.addassign(pos, v),
        il.setstate(il.array(text, pos)),
        cont.call(pos)))
    # lefttext: return left text
    'lefttext': (cont) -> cont.call(il.slice(il.index(il.state, 0), il.index(il.state, 1)))
    # subtext: return text[start...start+length]
    'subtext': (cont, length, start) ->
      text = @newvar('text'); pos = @newvar('pos')
      start1 = @newvar('start'); length1 = @newvar('length')
      start2 = @newvar('start'); length2 = @newvar('length')
      start3 = @newvar('start'); length3 = @newvar('length')
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
      text = @newvar('text')
      pos = @newvar('pos')
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
      fc = @newvar('fc')
      v = @newvar('v')
      il.begin(il.assign(fc, il.failcont),
        il.setfailcont(il.clamda(v,
          v,
          il.setfailcont(fc),
          @cont(exp, cont))),
        cont.call(null))
     # greedymay: greedy optional
    'greedymay': (cont, exp) ->
      fc = @newvar('fc')
      v = @newvar('v')
      v1 = @newvar('v')
      il.begin(il.assign(fc, il.failcont),
         il.setfailcont(il.clamda(v,
           il.assign(v1, v),
           il.setfailcont(fc),
           cont.call(v1))),
         @cont(exp, @clamda(v,il.assign(v1, v),
                    il.setfailcont(fc),
                    cont.call(v1))))
    'any': (cont, exp) ->
      fc = @newvar('fc')
      trail = @newvar('trail')
      state = @newvar('state')
      anyCont = @newvar('anyCont')
      anyCont.isRecursive = true
      v = @newvar('v')
      v1 = @newvar('v')
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
      fc = @newvar('fc')
      trail = @newvar('trail')
      v = @newvar('v')
      anyCont = @newvar('anyCont')
      anyFcont = @newvar('anyFcont')
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
      fc = @newvar('fc')
      anyCont = @newvar('anyCont')
      anyCont.isRecursive = true
      v = @newvar('v')
      v1 = @newvar('v')
      il.begin(
          il.assign(anyCont, il.recclamda(v, @cont(exp, anyCont))),
          il.assign(fc, il.failcont),
          il.setfailcont(il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))),
          anyCont.call(null))
    'parallel': (cont, x, y, checkFunction = (state, baseState) -> state[1] is baseState[1]) ->
      state = @newvar('state')
      right = @newvar('right')
      v = @newvar('v')
      v1 = @newvar('v')
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
      state = @newvar('state')
      v = @newvar('v')
      v1 = @newvar('v')
      state = @newvar('state')
      il.begin(il.assign(state, il.state),
               @cont(item, @clamda(v, il.assign(v1, v),
                                     il.setstate(state),
                                     cont.call(v))))

    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'notfollow': (cont, item) ->
      state = @newvar('state')
      fc = @newvar('fc')
      v = @newvar('v')
      v1 = @newvar('v')
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
      data = @newvar('data')
      pos = @newvar('pos')
      x = @newvar('x')
      c = @newvar('c')
      v = @newvar('v')
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
        params = (@newvar('a'+i) for i in [0...length])
        cont = cont.call(vop(params...))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], compiler.clamda(params[i], cont))
        cont

  for name in ['char', 'followChars', 'notFollowChars', 'charWhen', 'stringWhile', 'stringWhile0',
               'number', 'literal', 'followLiteral', 'quoteString']
    do (name=name, vop=vop) -> Compiler::specials[name] = (cont, item) ->
      compiler = @
      v = @newvar('v')
      compiler.cont(item, compiler.clamda(v, cont.call(il[name](il.solver, v))))

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
      v = @newvar('v')
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
      v = @newvar('v')
      cont = cont.call(quasilist)
      for i in [exp.length-1..1] by -1
        e = exp[i]
        if  _.isArray(e) and e.length>0 and e[0] is "unquote-slice"
          cont = @quasiquote(e, @clamda(v, il.assign(quasilist, il.concat(quasilist, v)), cont))
        else
          cont = @quasiquote(e, @clamda(v, il.push(quasilist, v), cont))
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

  interlang: (term) ->
    if _.isString(term) then return il.uservar(term)
    if not _.isArray(term) then return term
    length = term.length
    if length is 0 then return term
    head = term[0]
    if not _.isString(head) then return term
    if head is 'string' then return term[1]
    return term
    # should add stuffs such as 'cons', 'uarray', 'uobject', etc.
#    @specials.hasOwnProperty(head) then return term
    #    @specials[head].call(this, cont, exp[1...]...)

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

  lookup: (vari) ->
    bindings = @bindings
    if hasOwnProperty.call(bindings, vari) then return bindings[vari]
    else
      outer = @outer
      if outer then outer.lookup(vari)
      else throw new VarLookupError(vari)

  getvar: (vari) ->
    try v = @lookup(vari)
    catch e
      if e instanceof VarLookupError
        @bindings[vari] = v = @newvar(vari)
        v

exports.OptimizationEnv = class OptimizationEnv extends CpsEnv
  constructor: (@outer, @bindings, @lamda) ->
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
