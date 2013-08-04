# ##dao
fs = require("fs")
beautify = require('js-beautify').js_beautify
{isInteger, isString, isArray} = require("./util")
il = require("./interlang")

{ QUOTE, EVAL, STRING, BEGIN, NONLOCAL, VARIABLE, UNIQUEVAR, UNIQUECONST,\
  ASSIGN, AUGMENTASSIGN, INC, SUFFIXINC, DEC, SUFFIXDEC, INCP, SUFFIXINCP, DECP, SUFFIXDECP, IF,\
  SWITCH, RETURN, JSTHROW, JSFUN, DIRECT, PURE, EFFECT, IO,\
  LAMDA, MACRO, EVALARG, ARRAY, UARRAY, MAKEOBJECT, UOBJECT, CONS, FUNCALL, MACROCALL, JSFUNCALL, \
  FOR, FORIN, FOROF, TRY, BLOCK, BREAK, CONTINUE, CATCH, THROW,  UNWINDPROTECT, CALLCC, CALLFC,\
  QUASIQUOTE, UNQUOTE, UNQUOTESLICE,\
  LOGICVAR, DUMMYVAR , UNIFY, NOTUNIFY, IS, BIND, GETVALUE,\
  SUCCEED, FAIL, PUSHP, ORP, ORP2, ORP3, NOTP, NOTP2, NOTP3, IFP, REPEAT, CUTABLE, CUT, FINDALL, ONCE,\
  PARSE, PARSEDATA, SETPARSERSTATE, SETPARSERDATA, SETPARSERCURSOR, GETPARSERSTATE, GETPARSERDATA, GETPARSERCURSOR, EOI, BOI, EOL,\
  BOL, STEP, LEFTPARSERDATA, SUBPARSERDATA, NEXTCHAR,\
  MAY, LAZYMAY, GREEDYMAY, ANY, LAZYANY, GREEDYANY, PARALLEL, FOLLOW, NOTFOLLOW, \
  ADD, SUB, MUL, DIV, MOD, AND, OR, NOT, BITAND, BITOR, BITXOR, \
  LSHIFT, RSHIFT, EQ, NE, LE, LT, GT, GE, NEG, BITNOT,\
  SEXPR_HEAD_FIRST, SEXPR_HEAD_LAST, PUSH, LIST, INDEX, \
  ATTR, LENGTH, SLICE, POP, INSTANCEOF
} = require './util'

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
  code = beautify(code, { indent_size: 2, "brace_style": "collapse"})
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
    done = il.idcont()
    exps = [ il.assign(il.uservar('_'), il.require('underscore')),
             il.assign(il.uservar('__slice'), il.attr([], il.symbol('slice'))),
             il.assign(il.uservar('solve'), il.attr(il.require('./core'), il.symbol('solve'))),
             il.assign(il.uservar('parser'), il.require('./parser')),
             il.assign(il.uservar('solvecore'), il.require('./solve')),
             il.assign(il.uservar('Solver'), il.attr(il.uservar('solvecore'), il.symbol('Solver'))),
             il.assign(il.uservar('Trail'), il.attr(il.uservar('solvecore'), il.symbol('Trail'))),
             il.assign(il.uservar('Var'), il.attr(il.uservar('solvecore'), il.symbol('Var'))),
             il.assign(il.uservar('DummyVar'), il.attr(il.uservar('solvecore'), il.symbol('DummyVar'))),
             il.assign(il.uservar('solver'), il.new(il.symbol('Solver').call())),
             il.assign(il.uservar('UArray'), il.attr(il.uservar('solvecore'), il.symbol('UArray'))),
             il.assign(il.uservar('UObject'), il.attr(il.uservar('solvecore'), il.symbol('UObject'))),
             il.assign(il.uservar('Cons'), il.attr(il.uservar('solvecore'), il.symbol('Cons'))),
             il.assign(il.parsercursor, null),
             il.assign(il.catches, {}),
             il.assign(il.trail, il.newTrail),
             il.assign(il.failcont, done),
             il.assign(il.cutcont, il.failcont),
             il.userlamda([], @cont(exp, done)).call()]
    lamda = il.userlamda([], exps...)
    env = new OptimizationEnv(env, {})
    lamda = @optimize(lamda, env)
    lamda = lamda.jsify(@, env)
    exp = il.assign(il.attr(il.uservar('exports'), il.symbol('main')), lamda)
    exp.toCode(@)

  lookup: (name) ->
    try @env.lookup(name) catch e then name

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
  newvar: (v) -> if isString(v) then @env.newvar(il.internalvar(v)) else @env.newvar(v)
  newconst: (v) -> if isString(v) then @env.newconst(il.internalvar(v)) else @env.newconst(v)
  pushEnv: () -> @env = @env.extend()
  popEnv: () -> @env = @env.outer

  # alpha convert
  alpha: (exp) ->
    if isString(exp) then return @lookup(exp)
    if not isArray(exp) then return exp
    length = exp.length
    if length is 0 then return exp
    if length is 1 then exp
    head = exp[0]
    if not isInteger(head) then return exp
    if head<SEXPR_HEAD_FIRST or head>SEXPR_HEAD_LAST then throw new Error(exp)
    switch head
      when STRING, DIRECT, LOGICVAR, DUMMYVAR then exp
      when NONLOCAL
        result = [head];
        for name in exp[1...]
          result.push(@env.alphaName(name))
        result
      when VARIABLE
        result = [head]; (result.push(@env.alphaName(name)) for name in exp[1...]); result
      when ASSIGN
        left = exp[1]
        if isString(left) then left = @env.alphaName(left)
        else left = @alpha(left)
        [head, left, @alpha(exp[2])]
      when AUGMENTASSIGN then [head, exp[1], @alpha(exp[2]), @alpha(exp[3])]
      when UNIQUEVAR, UNIQUECONST then [head, @env.uniqueName(exp[1], exp[2])]
      when LAMDA
        result = [head]
        @pushEnv()
        params = exp[1]
        result.push(@env.alphaName(p) for p in params)
        for e in exp[2...] then result.push(@alpha(e))
        @popEnv()
        result
      when MACRO
        result = [head]
        @pushEnv()
        params = exp[1]
        result.push(@env.alphaName(p) for p in params)
        bindings = @env.bindings
        for p in exp[1] then bindings[p] = [EVALARG, bindings[p]]
        for e in exp[2...] then result.push(@alpha(e))
        @popEnv()
        result
      when BLOCK
        result = [head, exp[1]]
        for e in exp[2...] then result.push(@alpha(e))
        result
      when BREAK then [head, exp[1], @alpha(exp[2])]
      when CONTINUE then [head, exp[1]]
      else # BEGIN, etc.
        result = [head]
        for e in exp[1...] then result.push(@alpha(e))
        result

  # compile to continuation
  cont: (exp, cont) ->
    if isString(exp) then v = @uservar(exp); v.isConst = true; return cont.call(v)
    if not isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not isInteger(head) then return cont.call(exp)
    switch head
      when QUOTE then cont.call(exp[1])
      when EVAL
        v = @newconst('v')
        p = @newconst('path')
        @cont(exp[1], il.clamda(v, @cont(exp[1], il.clamda(p, cont.call(il.evalexpr(v, p))))))
      when STRING then cont.call(exp[1])
      when BEGIN then  @expsCont(exp[1...], cont)
      when NONLOCAL then il.begin(il.nonlocal((@uservar(name) for name in exp[1...])), cont.call(null))
      when VARIABLE
        for name in exp[1...]
          v = @uservar(name)
          delete v.isConst
        cont.call(null)
      when UNIQUEVAR then cont.call(@uservar(exp[1]))
      when UNIQUECONST then cont.call(@userconst(exp[1]))

      when ASSIGN then @leftValueCont(cont, ASSIGN, exp[1], exp[2])
      when AUGMENTASSIGN then @leftValueCont(cont, AUGMENTASSIGN, exp[2], exp[3], exp[1])
      when INC then @leftValueCont(cont, INC, exp[1])
      when SUFFIXINC then @leftValueCont(cont, SUFFIXINC, exp[1])
      when DEC then @leftValueCont(cont, DEC, exp[1])
      when SUFFIXDEC then @leftValueCont(cont, SUFFIXDEC, exp[1])
      when INCP then @leftValueCont(cont, INCP, exp[1])
      when SUFFIXINCP then @leftValueCont(cont, SUFFIXINCP, exp[1])
      when DECP then @leftValueCont(cont, DECP, exp[1])
      when SUFFIXDECP then @leftValueCont(cont, SUFFIXDECP, exp[1])

      when IF
        v = @newconst('v')
        @cont(exp[1], il.clamda(v, il.if_(v, @cont(exp[2], cont), @cont(exp[3], cont))))

      when SWITCH
        v = @newconst('v')
        k = @newconst('cont')
        clauses = exp[2...]
        length = clauses.length
        if length%2 is 1 then default1 = clauses[length-1]; clauses = clauses[0...length-1]
        else default1 = undefined

        clauses = for i in [0...length-1] by 2
          [(for value in clauses[i] then @cont(value, il.idcont())), @cont(clauses[i+1], k)]
        default1 = @cont(default1, k)
        il.begin(il.assign(k, cont), @cont(exp[1], il.clamda(v, il.switch(v, clauses,default1))))

      when JSFUN then f = il.jsfun(exp[1]);  f._effect = @_effect;  cont.call(f)
      when DIRECT then il.begin(exp[1], cont.call())
      when PURE
        oldEffect = @_effect
        @_effect = il.PURE
        result = @cont(exp[1], cont)
        @_effect = oldEffect
        result
      when EFFECT
        oldEffect = @_effect
        @_effect = il.EFFECT
        result = @cont(exp[1], cont)
        @_effect = oldEffect
        result
      when IO
        oldEffect = @_effect
        @_effect = il.IO
        result = @cont(exp[1], cont)
        @_effect = oldEffect
        result

      when LAMDA
        @pushEnv()
        params = (@uservar(p) for p in exp[1])
        k = @newconst('cont')
        params.push(k)
        cont = cont.call(il.userlamda(params, @expsCont(exp[2...], k)))
        @popEnv()
        cont
      when MACRO
        @pushEnv()
        params1 = (@uservar(p) for p in exp[1])
        k = @newconst('cont')
        params1.push(k)
        cont = cont.call(il.lamda(params1, @expsCont(exp[2...], k)))
        @popEnv()
        cont

      when EVALARG then cont.call(@uservar(exp[1]).call())

      when ARRAY
        args = exp[1...]
        compiler = @
        length = args.length
        xs = (@newconst('x'+i) for i in [0...length])
        cont = cont.call(il.array(xs...))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(xs[i], cont))
        cont
      when UARRAY
        args = exp[1...]
        compiler = @
        length = args.length
        xs = (@newconst('x'+i) for i in [0...length])
        cont = cont.call(il.uarray(xs...))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(xs[i], cont))
        cont
      when MAKEOBJECT
        args = exp[1...]
        compiler = @
        length = args.length
        obj = @newconst('object1')
        xs = (@newconst('x'+i) for i in [0...length])
        cont = il.begin(il.assign(obj, {}), il.setobject(obj, xs), cont.call(obj))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(xs[i], cont))
        cont
      when UOBJECT
        args = exp[1...]
        compiler = @
        length = args.length
        obj = @newconst('object1')
        uobj = @newconst('uobject1')
        xs = (@newconst('x'+i) for i in [0...length])
        cont = il.begin(il.assign(obj, {}), il.setobject(obj, xs), il.assign(uobj, il.uobject(obj)), cont.call(uobj))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(xs[i], cont))
        cont
      when CONS
        v = @newconst('v'); v1 = @newconst('v')
        @cont(exp[1], il.clamda(v, @cont(exp[2], il.clamda(v1, cont.call(il.cons(v, v1))))))

      when FUNCALL
        args = exp[2...]
        compiler = @
        f = @newconst('func')
        length = args.length
        params = (@newconst('arg'+i) for i in [0...length])
        params.push(cont)
        body = f.apply(params)
        for i in [length-1..0] by -1
          body = do (i=i, body=body) ->
            compiler.cont(args[i], il.clamda(params[i], body))
        @cont(exp[1], il.clamda(f, body))
      when MACROCALL
        args = exp[2...]
        compiler = @
        f = @newconst('macro')
        length = args.length
        params = (@newconst('arg'+i) for i in [0...length])
        params.push(cont)
        body = f.apply(params)
        for i in [length-1..0] by -1
          body = do (i=i, body=body) ->
            il.clamda(params[i], body).call(il.lamda([], compiler.cont(args[i], il.idcont())))
        @cont(exp[1], il.clamda(f, body))
      when JSFUNCALL
        args = exp[2...]
        compiler = @
        f = @newconst('func')
        length = args.length
        params = (@newconst('arg'+i) for i in [0...length])
        body = cont.call(f.apply(params))
        for i in [length-1..0] by -1
          body = do (i=i, body=body) ->
            compiler.cont(args[i], il.clamda(params[i], body))
        @cont(exp[1], il.clamda(f, body))

      when FOR
        init = il.lamda([], compiler.cont(exp[1], il.idcont())).call()
        test = il.lamda([], compiler.cont(exp[2], il.idcont())).call()
        step = il.lamda([], compiler.cont(exp[3], il.idcont())).call()
        body = compiler.expsCont(exp[4...], il.idcont())
        il.begin(il.for_(init, test, step, body), cont.call(null))
      when FORIN
        container = il.lamda([], compiler.cont(exp[2], il.idcont())).call()
        body = compiler.expsCont(exp[3...], il.idcont())
        il.begin(il.forin(@userconst(exp[0]), container), cont.call(null))
      when FOROF
        container = il.lamda([], compiler.cont(exp[2], il.idcont())).call()
        body = compiler.expsCont(exp[3...], il.idcont())
        il.begin(il.forof(@userconst(exp[1]), container), cont.call(null))
      when TRY
        test = il.lamda([], compiler.cont(exp[1], il.idcont())).call()
        catchBody = compiler.cont(exp[3], il.idcont())
        final = compiler.cont(exp[4], il.idcont())
        il.begin(il.try(test, @userconst(exp[2]), catchBody, final), cont.call(null))

      when QUASIQUOTE then @quasiquote(exp[1], cont)
      when UNQUOTE then throw new Error "unquote: too many unquote and unquoteSlice"
      when UNQUOTESLICE then throw new Error "unquoteSlice: too many unquote and unquoteSlice"

      # lisp style block
      when BLOCK
        label = exp[1][1]
        if not isString(label) then (label = ''; body = [label].concat(body))
        exits = @exits[label] ?= []
        exits.push(cont)
        defaultExits = @exits[''] ?= []  # if no label, go here
        defaultExits.push(cont)
        continues = @continues[label] ?= []
        f = @newconst(il.blockvar('block'+label))
        f.isRecursive = true
        fun = il.blocklamda(null)
        continues.push(f)
        defaultContinues = @continues[''] ?= []   # if no label, go here
        defaultContinues.push(f)
        fun.body = @expsCont(exp[2...], cont)
        exits.pop()
        if exits.length is 0 then delete @exits[label]
        continues.pop()
        if continues.length is 0 then delete @continues[label]
        defaultExits.pop()
        defaultContinues.pop()
        il.begin(il.assign(f, fun), f.call())

      when BREAK
        label = exp[1][1]
        exits = @exits[label]
        if not exits or exits==[] then throw new  Error(label)
        exitCont = exits[exits.length-1]
        cont = @cont(exp[2], @protect(exitCont))
        cont
      when CONTINUE
        label = exp[1][1]
        continues = @continues[label]
        if not continues or continues==[] then throw new  Error(label)
        continueCont = continues[continues.length-1]
        @protect(continueCont).call()

      # aka. lisp style catch/throw
      when CATCH
        v = @newconst('v'); v2 = @newconst('v')
        temp1 = @newconst('temp'); temp2 = @newconst('temp')
        @cont(exp[1], il.clamda(v, il.assign(temp1, v),
                              il.pushCatch(temp1, cont),
                              @expsCont(exp[2...], il.clamda(v2, il.assign(temp2, v2),
                                                        il.popCatch(temp1),
                                                        cont.call(temp2)))))
      when THROW
        v = @newconst('v'); v2 = @newconst('v'); temp = @newconst('temp'); temp2 = @newconst('temp')
        @cont(exp[1], il.clamda(v, il.assign(temp, v),
                              @cont(exp[2], il.clamda(v2, il.assign(temp2, v2),
                                                   @protect(il.findCatch(temp)).call(temp2)))))
      when UNWINDPROTECT
        oldprotect = @protect
        v1 = @newconst('v'); v2 = @newconst('v'); temp = @newconst('temp'); temp2 = @newconst('temp')
        compiler = @
        cleanup = exp[2...]
        @protect = (cont) -> il.clamda(v1, il.assign(temp, v1),
                                       compiler.expsCont(cleanup, il.clamda(v2, v2,
                                            oldprotect(cont).call(temp))))
        result = @cont(exp[1],  il.clamda(v1, il.assign(temp, v1),
                                @expsCont(cleanup, il.clamda(v2, v2,
                                      cont.call(temp)))))
        @protect = oldprotect
        result
      when RETURN
        il.begin(il.return(il.lamda([], @cont(exp[1], il.idcont())).call()), cont.call(null))
      when JSTHROW
        il.begin(il.throw(il.lamda([], @cont(exp[1], il.idcont())).call()), cont.call(null))
      when CALLCC
        v = @newconst('v'); k = @newconst('k')
        il.begin(il.assign(k, cont), @cont(exp[1], il.clamda(v, k.call(v.call(k, k)))))
      when CALLFC
        v = @newconst('v'); k = @newconst('k')
        il.begin(il.assign(k, cont), @cont(exp[1], il.clamda(v, k.call(v.call(il.failcont, k)))))

      when LOGICVAR then cont.call(il.newLogicVar(exp[1]))
      when DUMMYVAR then cont.call(il.newDummyVar(exp[1]))
      when UNIFY
        x1 = @newconst('x'); y1 = @newconst('y')
        @cont(exp[1], il.clamda(x1, @cont(exp[2], il.clamda(y1,
            il.if_(il.unify(x1, y1), cont.call(true),
               il.failcont.call(false))))))
      when NOTUNIFY
        x1 = @newconst('x'); y1 = @newconst('y')
        @cont(exp[1], il.clamda(x1, @cont(exp[2], il.clamda(y1,
            il.if_(il.unify(x, y), il.failcont.call(false),
               cont.call(true))))))
      # evaluate @exp and bind it to vari
      when IS
        v = @newconst('v')
        @cont(exp[2], il.clamda(v, il.bind(@userconst(exp[1]), v), cont.call(true)))
      when BIND then il.begin(il.bind(@userconst(exp[1]), il.deref(@interlang(exp[2]))), cont.call(true))
      when GETVALUE then cont.call(il.getvalue(@interlang(exp[1])))
      when SUCCEED then cont.call(true)
      when FAIL then il.failcont.call(false)

      # x.push(y), when backtracking here, x.pop()
      when PUSHP
        list1 = @newconst('list')
        value1 = @newconst('value')
        list2 = @newconst('list')
        value2 = @newconst('value')
        fc = @newconst('fc')
        v = @newconst('v')
        @cont(exp[1], il.clamda(list1,
            il.assign(list2, list1),
            @cont(exp[2], il.clamda(value1,
              il.assign(value2, value1),
              il.assign(fc, il.failcont),
              il.setfailcont(il.clamda(v, v, il.pop(list2), fc.call(value2)))
              il.push(list2, value2),
              cont.call(value2)))))

      when ORP
        v = @newconst('v')
        fc = @newconst('fc')
        il.begin(il.assign(fc, il.failcont),
                 il.setfailcont(il.clamda(v,
                                          v,
                                          il.setfailcont(fc),
                                          @cont(exp[2], cont))),
                 @cont(exp[1], cont))
      when ORP2
        v = @newconst('v')
        trail = @newconst('trail')
        fc = @newconst('fc')
        il.begin(il.assign(trail, il.trail),
                 il.assign(fc, il.failcont),
                 il.settrail(il.newTrail),
                 il.setfailcont(il.clamda(v,
                                          v,
                                          il.undotrail(il.trail),
                                          il.settrail(trail),
                                          il.setfailcont(fc),
                                          @cont(exp[2], cont))),
                 @cont(exp[1], cont))
      when ORP3
        v = @newconst('v')
        trail = @newconst('trail')
        parsercursor = @newconst('parsercursor')
        fc = @newconst('fc')
        il.begin(il.assign(trail, il.trail),
                 il.assign(parsercursor, il.parsercursor),
                 il.assign(fc, il.failcont),
                 il.settrail(il.newTrail),
                 il.setfailcont(il.clamda(v,
                                          v,
                                          il.undotrail(il.trail),
                                          il.settrail(trail),
                                          il.setparsercursor(parsercursor),
                                          il.setfailcont(fc),
                                          @cont(exp[2], cont))),
                 @cont(exp[1], cont))
      when IFP
        #if -> Then; _Else :- If, !, Then.<br/>
        #If -> _Then; Else :- !, Else.<br/>
        #If -> Then :- If, !, Then
        v = @newconst('v')
        fc = @newconst('fc')
        il.begin(il.assign(fc, il.failcont),
          @cont(exp[1], il.clamda(v,
            v,
            il.setfailcont(fc),
            @cont(exp[2], cont))))
      when NOTP
        v = @newconst('v')
        fc = @newconst('fc')
        il.begin(il.assign(fc, il.failcont),
                 il.setfailcont(il.clamda(v,
                                          v,
                                          il.setfailcont(fc),
                                          cont.call(false))),
                 @cont(exp[1], fc))
      when NOTP2
        v = @newconst('v')
        trail = @newconst('trail')
        fc = @newconst('fc')
        il.begin(il.assign(trail, il.trail),
                 il.settrail(il.newTrail),
                 il.assign(fc, il.failcont),
                 il.setfailcont(il.clamda(v,
                                          v,
                                          il.undotrail(il.trail),
                                          il.settrail(trail),
                                          il.setfailcont(fc),
                                          cont.call(false))),
                 @cont(exp[1], fc))
      when NOTP3
        v = @newconst('v')
        trail = @newconst('trail')
        parsercursor = @newconst('parsercursor')
        fc = @newconst('fc')
        il.begin(il.assign(trail, il.trail),
                 il.assign(fc, il.failcont),
                 il.assign(parsercursor, il.parsercursor),
                 il.settrail(il.newTrail),
                 il.setfailcont(il.clamda(v,
                                          v,
                                          il.undotrail(il.trail),
                                          il.settrail(trail),
                                          il.setparsercursor(parsercursor),
                                          il.setfailcont(fc),
                                          cont.call(false))),
                 @cont(exp[1], fc))
      when REPEAT then il.begin(il.setfailcont(cont), cont.call(null))
      when CUTABLE
        cc = @newconst('cutcont')
        v = @newconst('v')
        v1 = @newconst('v')
        il.begin(il.assign(cc, il.cutcont),
                 il.assign(il.cutcont, il.failcont),
                 @cont(exp[1], il.clamda(v, il.assign(v1, v), il.setcutcont(cc), cont.call(v1))))
      # prolog's cut, aka "!"
      when CUT then il.begin(il.setfailcont(il.cutcont), cont.call(null))
      # find all solution to the goal @exp in prolog
      when FINDALL
        fc = @newconst('fc')
        v = @newconst('v')
        v1 = @newconst('v')
        result = exp[2]; template = exp[3]
        if not result?
          il.begin(il.assign(fc, il.failcont),
                  il.setfailcont(il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))),
                  @cont(exp[1], il.failcont))
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
            @cont(exp[1], il.clamda(v, il.assign(v1, v),
              il.push(result1, il.getvalue(@interlang(template))),
              il.failcont.call(v1))))
      # find only one solution to the @goal
      when ONCE
        fc = @newconst('fc')
        v = @newconst('v')
        v1 = @newconst('v')
        il.begin(il.assign(fc, il.failcont),
          @cont(exp[1], il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))))

      when PARSE
        v = @newconst('v')
        v1 = @newconst('v')
        @cont(exp[2], il.clamda(v, il.assign(v1, v),
                                il.setparserdata(il.index(v1, 0))
                                il.setparsercursor(il.index(v1, 1))
                                @cont(exp[1], il.clamda(v, cont.call(v)))))
      when PARSEDATA
        v = @newconst('v')
        @cont(exp[2], il.clamda(v,
                            il.begin(il.setparserdata(v),
                               il.setparsercursor(0),
                               @cont(exp[1], il.clamda(v, cont.call(v))))))
      when SETPARSERSTATE
        v = @newconst('v'); v1 = @newconst('v')
        @cont(exp[1], il.clamda(v,
          il.assign(v1, v),
          il.setparserdata(il.index(v,0)),
          il.setparsercursor(il.index(v,1)),
          cont.call(true)))
      when SETPARSERDATA
        v = @newconst('v')
        @cont(exp[1], il.clamda(v, il.setparserdata(v), il.setparsercursor(0), cont.call(true)))
      when SETPARSERCURSOR
        v = @newconst('v')
        @cont(exp[1], il.clamda(v, il.setparsercursor(v), cont.call(true)))
      when GETPARSERSTATE then cont.call(il.array(il.parserdata, il.parsercursor))
      when GETPARSERDATA then cont.call(il.parserdata)
      when GETPARSERCURSOR then cont.call(il.parsercursor)
      when EOI
        data = @newconst('data'); pos = @newconst('pos')
        il.begin(il.assign(data, il.parserdata),
                 il.assign(pos, il.parsercursor),
                 il.if_(il.ge(pos, il.length(data)), cont.call(true), il.failcont.call(false)))
      when BOI then il.if_(il.eq(il.parsercursor, 0), cont.call(true), il.failcont.call(false))
      # eol: end of line text[pos] in "\r\n"
      when EOL
        text = @newconst('text'); pos = @newconst('pos');  c = @newconst('c')
        il.begin(
                  il.assign(text, il.parserdata),
                  il.assign(pos, il.parsercursor),
                  il.if_(il.ge(pos, il.length(text)), cont.call(true),
                       il.begin(
                         il.assign(c, il.index(text, pos, 1)),
                         il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                              cont.call(true),
                              il.failcont.call(false)))))
      when BOL
        text = @newconst('text'); pos = @newconst('pos');  c = @newconst('c')
        il.begin(
                  il.assign(text, il.parserdata),
                  il.assign(pos, il.parsercursor),
                  il.if_(il.eq(pos, 0), cont.call(true),
                           il.begin(
                               il.assign(c, il.index(text, il.sub(pos, 1))),
                               il.if_(il.or_(il.eq(c, "\r"), il.eq(c, "\n")),
                                      cont.call(true),
                                      il.failcont.call(false)))))

      when STEP
        v = @newconst('v')
        @cont(exp[1], il.clamda(v,
          il.setparsercursor(il.add(il.parsercursor, v))
          cont.call(il.parsercursor)))
      when LEFTPARSERDATA then cont.call(il.slice(il.parserdata, il.parsercursor))
      # subtext: text[start...start+length]
      when SUBPARSERDATA
        text = @newconst('text'); pos = @newconst('pos')
        start1 = @newconst('start'); length1 = @newconst('length')
        start2 = @newconst('start'); length2 = @newconst('length')
        start3 = @newconst('start'); length3 = @newconst('length')
        @cont(exp[1], il.clamda(length1,
          il.assign(length2, length1),
          @cont(exp[2], il.clamda(start1,
            il.assign(start2, start1),
            il.assign(text, il.parserdata),
            il.assign(pos, il.parsercursor),
            il.begin(il.assign(start3, il.if_(il.ne(start2, null), start2, pos)),
                     il.assign(length3, il.if_(il.ne(length2, null), length2, il.length(text))),
                     cont.call(il.slice(text, start3, il.add(start3, length3))))))))

      when NEXTCHAR then cont.call(il.index(il.parserdata, il.parsercursor))
      # ##### may, lazymay, greedymay
      # may: aka optional
      when MAY
        il.begin(
          il.appendFailcont(cont),
          @cont(exp[1], cont))
      # lazymay: lazy optional
      when LAZYMAY
        fc = @newconst('fc')
        v = @newconst('v')
        il.begin(il.assign(fc, il.failcont),
          il.setfailcont(il.clamda(v,
            v,
            il.setfailcont(fc),
            @cont(exp[1], cont))),
          cont.call(null))
       # greedymay: greedy optional
      when GREEDYMAY
        fc = @newconst('fc')
        v = @newconst('v')
        v1 = @newconst('v')
        v2 = @newconst('v')
        il.begin(il.assign(fc, il.failcont),
           il.setfailcont(il.clamda(v,
             il.assign(v1, v),
             il.setfailcont(fc),
             cont.call(v1))),
           @cont(exp[1], il.clamda(v,il.assign(v2, v),
                      il.setfailcont(fc),
                      cont.call(v2))))
      when ANY
        fc = @newconst('fc')
        trail = @newconst('trail')
        parsercursor = @newconst('parsercursor')
        anyCont = @newconst('anyCont')
        anyCont.isRecursive = true
        v = @newconst('v')
        v1 = @newconst('v')
        il.begin(
          il.assign(anyCont, il.recclamda(v,
                   il.assign(fc, il.failcont),
                   il.assign(trail, il.trail),
                   il.assign(parsercursor, il.parsercursor),
                   il.settrail(il.newTrail),
                   il.setfailcont(il.clamda(v,
                     il.assign(v1, v),
                     il.undotrail(il.trail),
                     il.settrail(trail),
                     il.setparsercursor(parsercursor),
                     il.setfailcont(fc),
                     cont.call(v1)))
                   @cont(exp[1], anyCont)))
           anyCont.call(null))
      when LAZYANY
        fc = @newconst('fc')
        v = @newconst('v')
        anyCont = @newconst('anyCont')
        anyFcont = @newconst('anyFcont')
        anyCont.isRecursive = true
        anyFcont.isRecursive = true
        il.begin(
          il.assign(anyCont, il.recclamda(v,
            il.setfailcont(anyFcont),
            cont.call(null))),
          il.assign(anyFcont, il.recclamda(v,
             il.setfailcont(fc),
             @cont(exp[1], anyCont))),
          il.assign(fc, il.failcont),
          anyCont.call(null))
      when GREEDYANY
        fc = @newconst('fc')
        anyCont = @newconst('anyCont')
        anyCont.isRecursive = true
        v = @newconst('v')
        v1 = @newconst('v')
        il.begin(
            il.assign(anyCont, il.recclamda(v, @cont(exp[1], anyCont))),
            il.assign(fc, il.failcont),
            il.setfailcont(il.clamda(v, il.assign(v1, v), il.setfailcont(fc), cont.call(v1))),
            anyCont.call(null))
      when PARALLEL
        checkFunction = exp[3] or ((parsercursor, baseParserCursor) -> parsercursor is baseParserCursor)
        parsercursor = @newconst('parsercursor')
        right = @newconst('right')
        v = @newconst('v')
        v1 = @newconst('v')
        il.begin(il.assign(parsercursor, il.parsercursor),
          @cont(exp[1],  il.clamda(v,
            v,
            il.assign(right, il.parsercursor),
            il.setparsercursor(parsercursor),
            @cont(exp[2], il.clamda(v, il.assign(v1, v),
                           il.if_(il.fun(checkFunction).call(il.parsercursor, right), cont.call(v1),
                              il.failcont.call(v1)))))))
      when FOLLOW
        parsercursor = @newconst('parsercursor')
        v = @newconst('v')
        v1 = @newconst('v')
        parsercursor = @newconst('parsercursor')
        il.begin(il.assign(parsercursor, il.parsercursor),
                 @cont(exp[1], il.clamda(v, il.assign(v1, v),
                                       il.setparsercursor(parsercursor),
                                       cont.call(v))))
      when NOTFOLLOW
        parsercursor = @newconst('parsercursor')
        fc = @newconst('fc')
        v = @newconst('v')
        v1 = @newconst('v')
        il.begin(
                il.assign(fc, il.failcont),
                il.assign(parsercursor, il.parsercursor),
                il.setfailcont(cont),
                @cont(exp[1], il.clamda(v,il.assign(v1, v),
                                       il.setparsercursor(parsercursor),
                                       fc.call(v1))))
      when ADD, SUB, MUL, DIV, MOD, AND, OR, NOT, BITAND, BITOR, BITXOR,\
          LSHIFT, RSHIFT, EQ, NE, LE, LT, GT, GE, NEG, BITNOT, PUSH, LIST, INDEX,\
          ATTR, LENGTH, SLICE, POP, INSTANCEOF
        vop = il.vopMaps[head]
        args = exp[1...]
        compiler = @
        length = args.length
        params = (@newconst('a'+i) for i in [0...length])
        cont = cont.call(vop(params...))
        for i in [length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            compiler.cont(args[i], il.clamda(params[i], cont))
        cont
      else throw new Error(exp)

  leftValueCont: (cont, task, item, exp, op) ->
    assignExpCont = (item) =>
      v = @newconst('v')
      temp = @newconst('temp')
      switch task
        when ASSIGN then @cont(exp, il.clamda(v, cont.call(il.assign(item, v))))
        when AUGMENTASSIGN then @cont(exp, il.clamda(v, cont.call(il.assign(item, il[op](item, v)))))
        when INC then cont.call(il.assign(item, il.add(item, 1)))
        when DEC then cont.call(il.assign(item, il.sub(item, 1)))
        when SUFFIXINC then il.begin(il.assign(temp, item), il.assign(item, il.add(item, 1)), cont.call(temp))
        when SUFFIXDEC then il.begin(il.assign(temp, item), il.assign(item, il.sub(item, 1)), cont.call(temp))
        when INCP
          fc = @newconst('fc')
          il.begin(il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.sub(item, 1)),fc.call(item))),
                          cont.call(il.assign(item, il.add(item, 1))))
        when DECP
          fc = @newconst('fc')
          il.begin(il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.add(item, 1)),fc.call(item))),
                          cont.call(il.assign(item, il.sub(item, 1))))
        when SUFFIXINCP
          fc = @newconst('fc')
          il.begin(il.assign(temp, item), il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.sub(item, 1)),fc.call(temp))),
                          il.assign(item, il.add(item, 1)),
                          cont.call(temp))
        when SUFFIXINCP
          fc = @newconst('fc')
          il.begin(il.assign(temp, item), il.assign(fc, il.failcont),
                          il.setfailcont(il.clamda(v, il.assign(item, il.add(item, 1)),fc.call(temp))),
                          il.assign(item, il.sub(item, 1)),
                          cont.call(temp))
    if  isString(item) then return assignExpCont(@uservar(item))
    if not isArray(item) then throw new Error "Left value should be an sexpression."
    length = item.length
    if length is 0 then throw new Error "Left value side should not be empty list."
    head = item[0]
    if not isInteger(head) then throw new Error "sexpression head should be a integer."
    if head is INDEX
      object = item[1]; index = item[2]
      obj = @newconst('obj')
      i = @newconst('i')
      @cont(object, il.clamda(obj, @cont(index, il.clamda(i, assignExpCont(il.index(obj, i))))))
    else if head is UNIQUEVAR then return assignExpCont(@uservar(item[1]))
    else if head is UNIQUECONST then return assignExpCont(@userconst(item[1]))
    else throw new Error "Left Value side should be assignable expression."

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw new  exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else
      v = @newconst('v')
      @cont(exps[0], il.clamda(v, v, @expsCont(exps[1...], cont)))

  quasiquote: (exp, cont) ->
    if not isArray(exp) then return cont.call(exp)
    length = exp.length
    if length is 0 then return cont.call(exp)
    head = exp[0]
    if not isInteger(head) then return cont.call(exp)
    if head<SEXPR_HEAD_FIRST or head>SEXPR_HEAD_LAST then return cont.call(exp)
    switch head
      when UNQUOTE then @cont(exp[1], cont)
      when UNQUOTESLICE then @cont(exp[1], cont)
      when QUOTE then cont.call(exp)
      when STRING then cont.call(exp)
      else
        quasilist = @newvar('quasilist')
        v = @newconst('v')
        cont = cont.call(quasilist)
        for i in [exp.length-1..1] by -1
          e = exp[i]
          if  isArray(e) and e.length>0 and e[0] is UNQUOTESLICE
            cont = @quasiquote(e, il.clamda(v, il.assign(quasilist, il.concat(quasilist, v)), cont))
          else
            cont = @quasiquote(e, il.clamda(v, il.push(quasilist, v), cont))
        il.begin( il.assign(quasilist, il.list(head)),
          cont)

  interlang: (term) ->
    if isString(term) then return @uservar(term)
    if not isArray(term) then return term
    length = term.length
    if length is 0 then return term
    head = term[0]
    if not isInteger(head) then return term
    if head is STRING then return term[1]
    if head is UNIQUEVAR then return @uservar(term)
    if head is UNIQUECONST then return @userconst(term)
    return term
    # should add stuffs such as 'cons', 'uarray', 'uobject', etc.
#    @specials.hasOwnProperty(head) then return term
    #    @specials[head].call(this, cont, exp[1...]...)

  optimize: (exp, env) ->
    expOptimize = exp?.optimize
    if expOptimize then expOptimize.call(exp, env, @)
    else exp

  toCode: (exp) ->
    exptoCode = exp?.toCode
    if exptoCode then exptoCode.call(exp, @)
    else if typeof exp is 'function' then exp.toString()
    else if exp is undefined then 'undefined'
    else JSON.stringify(exp)

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
      if vari.isConst
        outer = @outer
        if outer instanceof OptimizationEnv then outer.lookup(vari) else vari
      else vari

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

class VarLookupError
  constructor: (@vari) ->

exports.TypeError = class TypeError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error
