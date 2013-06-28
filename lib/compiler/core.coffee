# ##dao
_ = require("underscore")
fs = require("fs")
beautify = require('js-beautify').js_beautify
il = require("./interlang")

exports.solve = (exp, path) ->
  path = compile(exp, path)
  delete require.cache[require.resolve(path)]
  compiled = require(path)
  compiled.main()

compile = (exp, path) ->
  compiler = new Compiler()
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
    @index = 1


  compile: (exp) ->
    v = @il_vari('v')
    fromCont = @cont(exp, @clamda(v, il.throw(il.new(il.symbol('SolverFinish').call(v)))))
    f = il.assign(il.vari('exports.main'), il.clamda(v
          il.assign(il.solver, il.new(il.symbol('Solver').call())),
          il.assign(il.state, null),
          il.assign(il.catches, {}),
          il.assign(il.trail, il.newTrail),
          il.assign(il.failcont, il.clamda(v, il.throw(il.new(il.symbol('SolverFinish').call(v))))),
          il.assign(il.cutcont, il.failcont),
          il.run(il.clamda(v, fromCont))))
#    f = fromCont
    f.refMap = {}
    f.analyze(@, f.refMap)
#    f = f.optimize(new Env(), @)
    f = f.jsify()
    f.toCode(@)

  il_vari:(name) ->
    il.vari(name+'_$'+@index++)

  clamda: (v, body...) -> @globalCont = cont = il.clamda(v, body...); cont

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
      item = il.vari(item)
      v = @il_vari('v')
      switch task
        when 'assign' then return @cont(exp, @clamda(v, il.assign(item, v), cont.call(v)))
        when 'augment-assign'
          return @cont(exp, @clamda(v, new augmentOperators[op](item, v), cont.call(v)))
        when 'incp'
          fc = @il_vari('fc')
          return il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['dec'](item), fc.call(v))), cont.call(il['inc'](item)))
        when 'decp'
          fc = @il_vari('fc')
          return il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['inc'](item), fc)), cont.call(il['dec'](item)))
        when 'suffixincp'
          fc = @il_vari('fc')
          return il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['suffixdec'](item), fc.call(v))), cont.call(il['suffixinc'](item)))
        when 'suffixdecp'
          fc = @il_vari('fc')
          return il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['suffixinc'](item), fc)), cont.call(il['suffixdec'](item)))
        else # when 'inc', 'dec', 'suffixinc', 'suffixdec'
          return cont.call(il[task](item))

    if not _.isArray(item) then throw new Error "Left value should be an sexpression."
    length = item.length
    if length is 0 then throw new Error "Left value side should not be empty list."
    head = item[0]
    if not _.isString(head) then throw new Error "Keyword should be a string."
    if head is "index"
      object = item[1]; index = item[2]
      obj = @il_vari('obj'); i = @il_vari('i'); v = @il_vari('v')
      item = il.index(obj, i)
      switch task
        when 'assign' then cont1 = @cont(exp, @clamda(v,  il.assign(item, v), cont.call(v)))
        when 'augment-assign'
          cont1 = @cont(exp, @clamda(v, new augmentOperators[op](item, v), cont.call(v)))
        when 'incp'
          fc = @il_vari('fc')
          il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['dec'](item), fc.call(v))), cont.call(il['inc'](item)))
        when 'decp'
          fc = @il_vari('fc')
          il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['inc'](item), fc)), cont.call(il['dec'](item)))
        when 'suffixincp'
          fc = @il_vari('fc')
          il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['suffixdec'](item), fc.call(v))), cont.call(il['suffixinc'](item)))
        when 'suffixdecp'
          fc = @il_vari('fc')
          il.let_([fc, il.failcont], il.setfailcont(il.clamda(v, il['suffixinc'](item), fc)), cont.call(il['suffixdec'](item)))
        else cont1 = cont.call(il[task](item))
      @cont(object, il.clamda(obj, @cont(index, il.clamda(i, cont1))))
    else throw new Error "Left Value side should be assignable expression."

  specials:
    "quote": (cont, exp) -> cont.call(exp)
    "eval": (cont, exp, path) ->
      v = @il_vari('v')
      p = @il_vari('path')
      @cont(exp, @clamda(v, @cont(path, @clamda(p, cont.call(il.evalexpr(v, p))))))
    'string': (cont, exp) -> cont.call(exp)
    "begin": (cont, exps...) -> @expsCont(exps, cont)

    "assign": (cont, left, exp) ->  @leftValueCont(cont, "assign", left, exp)
    "augment-assign": (cont, op, left, exp) ->  @leftValueCont(cont, "augment-assign", left, exp, op)
    'inc': (cont, item) -> @leftValueCont(cont, "inc", item)
    'suffixinc': (cont, item) -> @leftValueCont(cont, "suffixinc", item)
    'dec': (item) ->  @leftValueCont(cont, "dec", item)
    'suffixdec': (item) ->  @leftValueCont(cont, "suffixdec", item)

    'incp': (cont, item) -> @leftValueCont(cont, "incp", item)
    'suffixincp': (cont, item) -> @leftValueCont(cont, "suffixincp", item)
    'decp': (item) ->  @leftValueCont(cont, "decp", item)
    'suffixdecp': (item) ->  @leftValueCont(cont, "suffixdecp", item)

    "if": (cont, test, then_, else_) ->
        v = @il_vari('v')
        @cont(test, @clamda(v, il.if_(v, @cont(then_, cont), @cont(else_, cont))))

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
      v = @il_vari('v')
      params = (il.vari(p) for p in params)
      globalCont = @globalCont
      cont = cont.call(il.lamda(params, @expsCont(body, @clamda(v, v))))
      @globalCont = globalCont
      cont

    "macro": (cont, params, body...) ->
      v = @il_vari('v')
      params1 = (il.vari(p) for p in params)
      body = (@substMacroArgs(body[i], params) for i in [0...body.length])
      globalCont = @globalCont
      cont = cont.call(il.lamda(params1, @expsCont(body, @clamda(v, v))))
      @globalCont = globalCont
      cont

    "evalarg": (cont, name) -> cont.call(il.vari(name).call(cont))

    "funcall": (cont, caller, args...) ->
      compiler = @
      f = @il_vari('f')
      length = args.length
      params = (@il_vari('a'+i) for i in [0...length])
      cont = cont.call(f.apply(params))
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          compiler.cont(args[i], compiler.clamda(params[i], cont))
      @cont(caller, @clamda(f, cont))

    "macall": (cont, caller, args...) ->
      compiler = @
      f = @il_vari('f'); v = @il_vari('v')
      length = args.length
      params = (@il_vari('a'+i) for i in [0...length])
      cont = f.apply(params)
      for i in [length-1..0] by -1
        cont = do (i=i, cont=cont) ->
          globalCont = compiler.globalCont
          compiler.globalCont = il.idcont
          body = compiler.cont(args[i], il.idcont)
          compiler.globalCont = globalCont
          compiler.clamda(params[i], cont).call(il.lamda([], body))
      @cont(caller, @clamda(f, cont))

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
      f = @il_vari('block'+label)
      fun = il.clamda(@il_vari('v'), null)
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
      @protect(continueCont).call(null)

    # aka. lisp style catch/throw
    'catch': (cont, tag, forms...) ->
      v = @il_vari('v'); v2 = @il_vari('v2')
      @cont(tag, @clamda(v,
                           il.pushCatch(v, cont),
                           @expsCont(forms, @clamda(v2
                                                      il.popCatch(v),
                                                      cont.call(v2)))))

    # aka lisp style throw
    "throw": (cont, tag, form) ->
      v = @il_vari('v'); v2 = @il_vari('v')
      @cont(tag, @clamda(v,
                           @cont(form, @clamda(v2,
                                                 @protect(il.findCatch(v)).call(v2)))))


    # aka. lisp's unwind-protect
    'unwind-protect': (cont, form, cleanup...) ->
      oldprotect = @protect
      v1 = @il_vari('v'); v2 = @il_vari('v')
      compiler = @
      @protect = (cont) -> compiler.clamda(v1,
                                     compiler.expsCont(cleanup, compiler.clamda(v2,
                                          oldprotect(cont).call(v1))))
      result = @cont(form,  compiler.clamda(v1,
                              @expsCont(cleanup, @clamda(v2,
                                    cont.call(v1)))))
      @protect = oldprotect
      result

    # aka. lisp's call/cc
    # callcc(someFunction(kont) -> body)
    #current continuation @cont can be captured in someFunction
    'callcc': (cont, fun) ->
      v = @il_vari('v')
      @cont(fun, @clamda(v, cont.call(v.call(cont, cont))))

    # aka. lisp's call/fc
    # callfc(someFunction(kont) -> body)
    #current continuation @cont can be captured in someFunction
    'callfc': (cont, fun) ->
      v = @il_vari('v')
      @cont(fun, @clamda(v, cont.call(v.call(il.failcont, cont))))

    'logicvar': (cont, name) -> cont.call(il.newLogicVar(name))
    'dummy': (cont, name) -> cont.call(il.newDummyVar(name))
    'unify': (cont, x, y) ->
      x1 = @il_vari('x'); y1 = @il_vari('y')
      @cont(x, @clamda(x1, @cont(y, @clamda(y1,
          il.if_(il.unify(x1, y1), cont.call(true),
             il.failcont.call(false))))))
    'notunify': (cont, x, y) ->
      x1 = @il_vari('x'); y1 = @il_vari('y')
      @cont(x, @clamda(x1, @cont(y, @clamda(y1,
          il.if_(il.unify(x, y), il.failcont.call(false),
             cont.call(true))))))
    # evaluate @exp and bind it to vari
    'is': (cont, vari, exp) ->
      v = @il_vari('v')
      @cont(exp, @clamda(v, il.bind(vari, v), cont.call(true)))
    'bind': (cont, vari, term) -> il.begin(il.bind(vari, il.deref(term)), cont.call(true))
    'getvalue': (cont, term) -> cont.call(il.getvalue(@interlang(term)))
    'succeed': (cont) -> cont.call(true)
    'fail': (cont) -> il.failcont.call(false)

    # x.push(y), when backtracking here, x.pop()
    'pushp': (cont, list, value) ->
      list1 = @il_vari('list')
      value1 = @il_vari('value')
      fc = @il_vari('fc')
      v = @il_vari('v')
      @cont(list, @clamda(list1,
        @cont(value, @clamda(value1,
          il.let_([fc, il.failcont],
            il.setfailcont(il.clamda(v, il.pop(list1), fc.call(v)))
            il.push(list1, value1),
            cont.call(value1))))))

    'orp': (cont, x, y) ->
      v = @il_vari('v')
      trail = @il_vari('trail')
      state = @il_vari('state')
      fc = @il_vari('fc')
      il.let_([trail, il.trail,
               state, il.state,
               fc, il.failcont],
           il.settrail(il.newTrail),
           il.setfailcont(il.clamda(v,
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
      v = @il_vari('v')
      fc = @il_vari('fc')
      il.let_([fc, il.failcont],
        @cont(test, @clamda(v,
          il.setfailcont(fc),
          @cont(action, cont))))

    #like in prolog, failure as negation.
    'notp': (cont, goal) ->
      v = @il_vari('v')
      trail = @il_vari('trail')
      state = @il_vari('state')
      fc = @il_vari('fc')
      il.let_([trail, il.trail,
               fc, il.failcont,
               state, il.state],
            il.settrail(il.newTrail),
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
      cc = @il_vari('cutcont')
      v = @il_vari('v')
      il.let_([cc, il.cutcont],
               il.assign(il.cutcont, il.failcont),
               @cont(goal, @clamda(v, il.setcutcont(cc), cont.call(v))))
    # prolog's cut, aka "!"
    'cut': (cont) -> il.begin(il.setfailcont(il.cutcont), cont.call(null))
    # find all solution to the goal @exp in prolog
    'findall': (cont, goal, result, template) ->
      fc = @il_vari('fc')
      v = @il_vari('v')
      if not result?
        il.let_([fc, il.failcont],
                il.setfailcont(il.clamda(v, il.setfailcont(fc), cont.call(v))),
                @cont(goal, il.failcont))
      else
        result1 = @il_vari('result')
        il.let_([result1, [],
                fc, il.failcont],
          il.setfailcont(il.clamda(v,
            il.if_(il.unify(result, result1), fc.call(v),
                   il.begin(il.setfailcont(fc), cont.call(v))))),
          @cont(exp, @clamda(v,
            il.push(result1, il.getvalue(template)),
            il.failcont.call(v))))

    # find only one solution to the @goal
    'once': (cont, goal) ->
      fc = @il_vari('fc')
      v = @il_vari('v')
      il.let_([fc, il.failcont],
        @cont(goal, @clamda(v, il.setfailcont(fc), cont.call(v))))

    'parse': (cont, exp, state) ->
      v = @il_vari('v')
      oldState = @il_vari('state')
      @cont(state, @clamda(v,
                             il.let_([oldState, il.state],
                               il.setstate(v),
                               @cont(exp, @clamda(v, il.setstate(oldState), cont.call(v))))) )
    'parsetext': (cont, exp, text) ->
      v = @il_vari('v')
      oldState = @il_vari('state')
      @cont(text, @clamda(v,
                          il.let_([oldState, il.state],
                             il.setstate(il.array(v, 0)),
                             @cont(exp, @clamda(v, il.setstate(oldState), cont.call(v))))))
    'setstate': (cont, state) ->
      v = @il_vari('v')
      @cont(state, @clamda(v, il.setstate(v), cont.call(v)))
    'settext': (cont, text) ->
      v = @il_vari('v')
      @cont(text, @clamda(v, il.setstate(il.array(v, 0)), cont.call(v)))
    'setpos': (cont, pos) ->
      v = @il_vari('v')
      @cont(pos, @clamda(v, il.assign(il.index(il.state, 1), v), cont.call(v)))
    'getstate': (cont) -> cont.call(il.state)
    'gettext': (cont) -> cont.call(il.index(il.state, 0))
    'getpos': (cont) -> cont.call(il.index(il.state, 1))
    'eoi': (cont) ->
      data = @il_vari('data'); pos = @il_vari('pos')
      il.begin(il.listlet([data, pos, il.state],
                 il.if_(il.ge(pos, il.length(data)), cont.call(true), il.failcont.call(false))))
    'boi': (cont) -> il.if_(il.eq(il.index(il.state, 1), 0), cont.call(true), il.failcont.call(false))
    # eol: end of line text[pos] in "\r\n"
    'eol': (cont) ->
      text = @il_vari('text'); pos = @il_vari('pos');  c = @il_vari('c')
      il.begin(
                il.listlet([text, pos, il.state],
                  il.if_(il.ge(pos, il.length(text)), cont.call(true),
                       il.begin(
                         il.assign(c, il.index(text, pos, 1)),
                         il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                              cont.call(true),
                              il.failcont.call(false))))))
    'bol': (cont) ->
      text = @il_vari('text'); pos = @il_vari('pos');  c = @il_vari('c')
      il.begin(
                il.listlet([text, pos, il.state],
                il.if_(il.eq(pos, 0), cont.call(true),
                         il.begin(
                             il.assign(c, il.index(text, il.sub(pos, 1))),
                             il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                                    cont.call(true),
                                    il.failcont.call(false))))))

    'step': (cont, n) ->
      v = @il_vari('v'); text = @il_vari('text'); pos = @il_vari('pos');
      @cont(n, @clamda(v,
        il.listlet([text, pos, il.state],
          il.addassign(pos, v),
          il.setstate(il.array(text, pos)),
          cont.call(pos))))
    # lefttext: return left text
    'lefttext': (cont) -> cont.call(il.slice(il.index(il.state, 0), il.index(il.state, 1)))
    # subtext: return text[start...start+length]
    'subtext': (cont, length, start) ->
       text = @il_vari('text'); pos = @il_vari('pos')
       start1 = @il_vari('start'); length1 = @il_vari('length')
       il.begin(
        il.listlet([text, pos, il.state],
        il.let_([start1, il.if_(il.ne(start, null), start, pos),
                 length1, il.if_(il.ne(length, null), length, il.length(text))],
        cont.call(il.slice(text, start1, il.add(start1, length1))))))

    # nextchar: text[pos]
    'nextchar': (cont) ->
      text = @il_vari('text')
      pos = @il_vari('pos')
      il.begin(
          il.listlet([text, pos, il.state],
          cont.call(il.index(text, pos))))
    # ##### may, lazymay, greedymay
    # may: aka optional
    'may': (cont, exp) ->
      il.begin(
        il.appendFailcont(cont),
        @cont(exp, cont))
    # lazymay: lazy optional
    'lazymay': (cont, exp) ->
      fc = @il_vari('fc')
      v = @il_vari('v')
      il.let_([fc, il.failcont],
        il.setfailcont(il.clamda(v,
          il.setfailcont(fc),
          @cont(exp, cont))),
        cont.call(null))
     # greedymay: greedy optional
    'greedymay': (cont, exp) ->
      fc = @il_vari('fc')
      v = @il_vari('v')
      il.let_([fc, il.failcont],
         il.setfailcont(il.clamda(v,
           il.setfailcont(fc),
           cont.call(v))),
         @cont(exp, @clamda(v,
                    il.setfailcont(fc),
                    cont.call(v))))
    'any': (cont, exp) ->
      fc = @il_vari('fc')
      trail = @il_vari('trail')
      state = @il_vari('state')
      anyCont = @il_vari('anyCont')
      v = @il_vari('v')
      il.begin(
        il.assign(anyCont, il.clamda(v,
        il.let_([fc, il.failcont,
                 trail, il.trail,
                 state, il.state],
          il.settrail(il.newTrail),
          il.setfailcont(il.clamda(v,
            il.undotrail(il.trail),
            il.settrail(trail),
            il.setstate(state),
            il.setfailcont(fc),
            cont.call(v)))
          @cont(exp, anyCont))))
        anyCont.call(null))
    'lazyany': (cont, exp) ->
      fc = @il_vari('fc')
      trail = @il_vari('trail')
      v = @il_vari('v')
      anyCont = @il_vari('anyCont')
      anyFcont = @il_vari('anyFcont')
      il.begin(
        il.assign(anyCont, il.clamda(v,
          il.assign(trail, il.trail),
          il.settrail(il.newTrail),
          il.setfailcont(anyFcont),
          cont.call(v))),
        il.assign(anyFcont, il.clamda(v,
           il.undotrail(il.trail),
           il.settrail(trail),
           il.setfailcont(fc),
           @cont(exp, anyCont))),
        il.assign(fc, il.failcont),
        anyCont.call(null))
    'greedyany': (cont, exp) ->
      fc = @il_vari('fc')
      anyCont = @il_vari('anyCont')
      v = @il_vari('v')
      il.begin(
          il.assign(anyCont, il.clamda(v, @cont(exp, anyCont))),
          il.assign(fc, il.failcont),
          il.setfailcont(il.clamda(v, il.setfailcont(fc), cont.call(v))),
          anyCont.call(null))
    'parallel': (cont, x, y, checkFunction = (state, baseState) -> state[1] is baseState[1]) ->
      state = @il_vari('state')
      right = @il_vari('right')
      v = @il_vari('v')
      il.let_([state, il.state],
        @cont(x,  @clamda(v,
        il.assign(right, il.state),
        il.setstate(state),
        @cont(y, @clamda(v,
          il.if_(il.fun(checkFunction).call(il.state, right), cont.call(v),
                il.failcont.call(false)))))))
    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'follow': (cont, item) ->
      state = @il_vari('state')
      v = @il_vari('v')
      state = @il_vari('state')
      il.let_(
               [state, il.state],
               @cont(item, @clamda(v,
                                     il.setstate(state),
                                     cont.call(v))))

    # follow: if item is followed, succeed, else fail. after eval, state is restored
    'notfollow': (cont, item) ->
      state = @il_vari('state')
      fc = @il_vari('fc')
      v = @il_vari('v')
      il.let_(
               [fc, il.failcont,
                state, il.state],
               il.setfailcont(cont),
               @cont(item, @clamda(v,
                                     il.setstate(state),
                                     fc.call(v))))

    # char: match one char  <br/>
    #  if x is char or bound to char, then match that given char with next<br/>
    #  else match with next char, and bound x to it.
    'xxxchar': (cont, item) ->
      data = @il_vari('data')
      pos = @il_vari('pos')
      x = @il_vari('x')
      c = @il_vari('c')
      v = @il_vari('v')
      @cont(item, @clamda(v,
          il.listlet([data, pos, il.state],
            il.if_(il.gt(pos, il.length(data)), il.return(il.failcont.call(v))),
            il.let_([x, il.deref(v),
                     c, il.index(data, pos)],
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
                 il.throw(il.new(il.symbol('TypeError').call(x))))))))

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
        params = (@il_vari('a'+i) for i in [0...length])
        cont = cont.call(vop(params...))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], compiler.clamda(params[i], cont))
        cont

  for name in ['char', 'followChars', 'notFollowChars', 'charWhen', 'stringWhile', 'stringWhile0',
               'number', 'literal', 'followLiteral', 'quoteString']
    do (name=name, vop=vop) -> Compiler::specials[name] = (cont, item) ->
      compiler = @
      v = @il_vari('v')
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
      v = @il_vari('v')
      @cont(exps[0], @clamda(v, @expsCont(exps[1...], cont)))

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
      quasilist = @il_vari('quasilist')
      v = @il_vari('v')
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
    if _.isString(term) then return il.vari(term)
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

augmentOperators = {add: il.addassign, sub: il.subassign, mul: il.mulassign, div: il.divassign, mod: il.modassign,
'and': il.andassign, 'or': il.orassign, bitand: il.bitandassign, bitor:il.bitorassign, bitxor: il.bitxorassign,
lshift: il.lshiftassign, rshift: il.rshiftassign
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
