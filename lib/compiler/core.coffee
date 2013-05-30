# ##dao
# ###a functional logic solver, with builtin parser.
# continuation pass style, two continuations, one for succeed, one for fail and backtracking. <br/>

# #### what's new 0.1.11
# findall: get result by template
# bug fix: special arity checking take account of (solver, cont, args...)

_ = require('underscore')
il = require("./interlang")

# ####solve
# use this utlity to solve a dao expression exp<br/>
#cont: (v) -> body # in coffeescript <br/>
#function(v){ body } # in javascript<br/>
#when solver succeed at last, @cont is executed.<br/>
#failcont: (v) -> body  # in coffeescript<br/>
#function(v){ body } # in javascript<br/>
#when solver fails at last, @failcont is executed.<br/>
#state: the state of solver, mainly used for parsing <br/>

exports.solve = (exp, state) ->
  exports.status = exports.UNKNOWN
  new exports.Compiler(state).solve(exp)

# ####class Compiler
# the compiler for dao expression
class exports.Compiler
  constructor: (
    # @exits play with block/break
    @exits = {},
    # like above, @continues play with block/continue
    @continues = {}
    ) ->
    @nameToVarIndex = {}
    v = @vari('v')
    @done = il.clamda(v, il.return(il.array(il.null, v)))

  # use this solver to solve exp, cont=done is the succeed continuation.
  solve: (exp, toCont = @done) ->
    fromCont = @cont(exp, toCont)
    code1 = "(#{fromCont.toCode(@)})"
    console.log code1
    f = fromCont.optimize(new Env(), @)
    code = "(#{f.toCode(@)})"
    console.log code
    fromCont = eval(code)
    [cont, value] = @run(null, fromCont)
    value

  # compile to continuation
  cont: (exp, cont) ->
    expCont = exp?.cont
    if expCont then expCont.call(exp, @, cont)
    else
      v = @vari('v')
      il.clamda(v, il.return(il.array(cont, exp)))

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
      else if _.isString(exp) then JSON.strinify(exp)
      else throw new TypeError(exp)

  # run the trampoline from cont until @finished is true.
  run: (value, cont) ->
    while cont
      [cont, value] = cont(value)
    [cont, value]


  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else @cont(exps[0], @expsCont(exps[1...], cont))

  # evaluate an array of expression to a array.
  argsCont: (args, cont) ->
    length = args.length
    params = @vari('a') for x in args
    compiler = @
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        _cont = (argi) ->  (params.push(argi); cont(params))
        compiler.cont(args[i], _cont)
    cont

  # used by lisp style quasiquote, unquote, unquoteSlice
  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v) -> cont(exp))

  vari: (name) ->
    index = @nameToVarIndex[name] or 0
    @nameToVarIndex[name] = index+1
    new il.vari(name+(if index then index else ''))

class Env
  constructor: (@data={}) ->
  extend: (vari, value) ->  @data[vari.name] = value; @
  lookup: (vari) -> data = @data; name = vari.name; if data.hasOwnProperty(name) then return data[name] else vari
# ####class Var
# Var for logic bindings, used in unify, lisp.assign, inc/dec, parser operation, etc.
Var = class exports.Var
  constructor: (@name, @binding = @) ->

  cont: (compiler, cont) -> (v) => cont(@deref(compiler.trail))

  toString:() -> "vari(#{@name})"

reElements = /\s*,\s*|\s+/

# utilities for new variables
# sometiems, say in macro, we need unique var to avoid name conflict
nameToIndexMap = {}
exports.vari = (name) ->
  index = nameToIndexMap[name] or 1
  nameToIndexMap[name] = index+1
  new Var(name+index)

exports.vars = (names) -> vari(name) for name in split names,  reElements

# DummyVar never fail when it unify. see tests on any/some/times in test_parser for examples
exports.DummyVar = class DummyVar extends Var
  constructor: (name) -> @name = '_$'+name
  cont:(compiler, cont) -> (v) => cont(@binding)

# nottodo: variable's applyCont:: canceled. lisp1 should be good.
exports.dummy = dummy = (name) ->
  index = nameToIndexMap[name] or 1
  nameToIndexMap[name] = index+1
  new exports.DummyVar(name+index)
exports.dummies = (names) -> new dummy(name) for name in split names,  reElements

# ####class Apply
# Apply to some Command(special, fun, macro, proc, etc)
class exports.Apply
  constructor: (@caller, @args) ->
    # declare the command's arity when define the command. <br/>
    # see builtins/*.coffee for examples.<br/>
    # null: (...)<br/>
    # [2, 4]: (a, b), (a, b, c, d)<br/>
    # -1: (a, b...);   -2: (a, b, c...)<br/>
    # 1: (a);      3: (a, b, c)<br/>
    length = args.length; arity = @caller.arity
    ok = false
    if arity is null then ok = true
    if _.isArray(arity)
      if length in arity then ok = true
    else if _.isNumber(arity)
      if (arity>=0 and length is arity) or (arity<0 and length>=-arity) then ok = true
    if not ok
      for x in @args
        if x?.caller?.name is "unquoteSlice" then return
      throw new ArityError(@)
    # used in macro.applyCont, to prevent maximum recursive depth error

  toString: -> "#{@caller}(#{@args.join(', ')})"

  # get the continuation of an instance of Apply based on cont
  cont: (compiler, cont) -> @caller.applyCont(compiler, cont, @args)

  # play with lisp style quasiquote/unquote/unquoteSlice
  quasiquote:  (compiler, cont) ->
    if @caller.name is "unquote"
      return  compiler.cont(@args[0], (v) -> cont(v))
    else if @caller.name is "unquoteSlice"
      # use the flag class UnquoteSliceValue to find unquoteSlice expression
      return compiler.cont(@args[0], (v) -> cont(new UnquoteSliceValue(v)))
    params = []
    cont = do (cont=cont) => ((v) => [cont, new @constructor(@caller, params)])
    args = @args
    for i in [args.length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.quasiquote(args[i], (v) ->
          if v instanceof UnquoteSliceValue
            for x in v.value then params.push x
          else params.push(v);
          cont(null))
    cont

# A flag class is used to process unquoteSlice
UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

# #### class Command
# dao command that can be applied <br/>
#  Special, Fun, Macro, Proc is subclass of Command.
Command = class exports.Command
  @directRun = false
  constructor: (@fun, @name, @arity) ->
    @callable = (args...) =>
      applied = new exports.Apply(@, args)
      if Command.directRun
        solver = Command.globalSolver
        result = solver.solve(applied)
        solver.finished = false
        result
      else applied
    @callable.arity = @arity

  register: (exports) -> exports[@name] = @callable
  toString: () -> @name

# update when v0.1.10, according to mscdex <mscdex@gmail.com> advice.
commandMaker = (klass) -> (arity, name, fun) ->
  if not name? and not fun?
    fun = arity
    name = "noname"
    # bugfix(0.1.11): Special has special fun's signature (compiler, cont, args...)
    if klass is exports.Special then arity = fun.length - 2
    else arity = fun.length
  else if not fun?
    fun = name
    if _.isString(arity)
      name = arity;
      if klass is exports.Special then arity = fun.length - 2
      else arity = fun.length
    else
      if not _.isNumber(arity) and arity isnt null and not _.isArray(arity) then throw new ArgumentError(arity)
      name = "noname"
  else
    if not _.isNumber(arity) and arity isnt null and not _.isArray(arity) then throw new ArgumentError(arity)
    if not  _.isString(name) then throw new TypeError(name)
  new klass(fun, name, arity).callable

# Speical knows compiler and cont, with them the special function has full control of things.
class exports.Special extends exports.Command
  applyCont: (compiler, cont, args) -> @fun(compiler, cont, args...)

# generate an instance of Special from a function <br/>
#  example:<br/>
#  begin = special(null, 'begin', (compiler, cont, exps...) -> compiler.expsCont(exps, cont))  # coffeescript <br/>
#  exports.begin = special(null, 'begin', function() { # javascript <br/>
#    var cont, exps, compiler; <br/>
#    <br/>
#    compiler = arguments[0], cont = arguments[1], exps = 3 <= arguments.length ? __slice.call(arguments, 2) : [];<br/>
#    return compiler.expsCont(exps, cont);<br/>
#  });<br/>
#  exports.fail = special(0, 'fail', (compiler, cont) -> (v) -> compiler.failcont(v))() #coffescript <br/>
#  exports.fail = special(0, 'fail', function(compiler, cont) { # javascript <br/>
#    return function(v) { <br/>
#      return compiler.failcont(v);<br/>
#    }; <br/>
#  })();<br/>
#
exports.special = special = commandMaker(exports.Special)

# KISS: to keep it simple, not to implmenting the applyCont in Var and Apply<br/>
# call goal with args...
exports.call = special(-1, 'call', (compiler, cont, goal, args...) ->
  goal1 = null
  argsCont =  compiler.argsCont(args, (params,  compiler) ->
    compiler.cont(goal1(params...), cont)(null))
  compiler.cont(goal, (v) -> goal1 = goal; argsCont(null)))

# apply goal with args
exports.apply  = special(2, 'apply', (compiler, cont, goal, args) ->
  goal1 = null
  argsCont =  compiler.argsCont(args, (params,  compiler) ->
    compiler.cont(goal1(params...), cont)(null))
  compiler.cont(goal, (v) -> goal1 = goal; argsCont(null)))

# Fun evaluate its arguments, and return the result to fun(params...) to cont directly.
class exports.Fun extends exports.Command
  applyCont: (compiler, cont, args) ->
    length = args.length
    params = @vari('a') for x in args
    cont = cont.call(il.apply(@fun, il.array(params)))
    compiler = @
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.cont(args[i], il.clamda(params[i], cont))
    cont

# generate an instance of Fun from a function <br/>
#  example:  <br/>
#  add = fun((x, y) -> x+y ) # coffeescript <br/>
#  add = fun(function(x,y){ return x+y; } # javascript <br/>
exports.fun = commandMaker(exports.Fun)

# Fun2 evaluate its arguments, and evaluate the result of fun(params...) again
class exports.Fun2 extends exports.Command
  applyCont: (compiler, cont, args) ->
    fun = @fun
    compiler.argsCont(args, (params) ->
      compiler.cont(fun(params...), cont)(params))

# generate an instance of Fun from a function <br/>
#  example:  <br/>
#  add = fun((x, y) -> x+y ) # coffeescript <br/>
#  add = fun(function(x,y){ return x+y; } # javascript <br/>
exports.fun2 = commandMaker(exports.Fun2)

# similar to lisp'macro, Macro does NOT evaluate its arguments, but evaluate the result to fun(args).
exports.Macro = class Macro extends exports.Command
  @idMap: {}
  @id: 0
  constructor: (@fun, @name, @arity) ->
    super
    @id = (Macro.id++).toString()

  applyCont: (compiler, cont, args) ->
    exp = @fun(args...)
#    compiler.cont(exp, cont)
    # prevent max recursive macro extend
    idMap =  Macro.idMap
    id = @id
    if not idMap[id] then idMap[id] = true; result = compiler.cont(exp, cont); delete idMap[id]; result
    else (v) ->  delete idMap[id]; compiler.cont(exp, cont)(v)

# generate a instance of Macro from a function <br/>
#  example:   <br/>
#  orpm = fun((x, y) -> orp(x,y ) # coffeescript<br/>
#  orpm = fun(function(x,y){  return orp(x,y ); } # javascript
exports.macro = commandMaker(exports.Macro)

# In Proc's function, the dao's expressions can be directly evaluated
class exports.Proc extends exports.Command
  applyCont:  (compiler, cont, args) ->
    (v) =>
      Command.directRun = true
      savedSolver = Command.globalSolver
      Command.globalSolver = compiler
      result = @fun(args...)
      Command.globalSolver = savedSolver
      Command.directRun = false
      [cont, result,  compiler]

exports.proc = commandMaker(exports.Proc)

exports.tofun = (name, cmd) ->
  # evaluate the arguments of a command before execute it<br/>.
#    with tofun, Special and Macro can behaviour like a Fun.<br/>
#    cmd can be an instance of subclass of Command, <br/>
#     especially macro(macro don't eval its arguments) <br/>
#     and specials that don't eval their arguments.
  unless cmd? then (cmd = name; name = 'noname')
  special(cmd.arity, name, (compiler, cont, args...) ->
          compiler.argsCont(args, (params) -> [compiler.cont(cmd(params...), cont), params]))

exports.UObject = class UObject
  constructor: (@data) ->

  getvalue: (trail, memo) ->
    result = {}
    changed = false
    for key, value of @data
      v = trail.getvalue(value, memo)
      if v isnt value then changed = true
      result[key] = v
    if changed then new UObject(result)
    else @

  unify: (y, trail) ->
    xdata = @data; ydata = y.data
    ykeys = Object.keys(y)
    for key of xdata
      index = ykeys.indexOf(key)
      if index==-1 then return false
      if not trail.unify(xdata[key], ydata[key]) then return false
      ykeys.splice(index, 1);
    if ykeys.length isnt 0 then return false
    true

# make unifable object
exports.uobject = (x) -> new UObject(x)

exports.UArray = class UArray
  constructor: (@data) ->

  getvalue: (trail, memo={}) ->
    result = []
    changed = false
    for x in @data
      v = trail.getvalue(x, memo)
      if v isnt x then changed = true
      result.push(v)
    if changed then new UArray(result)
    else @

  unify: (y, trail) ->
    xdata = @data; ydata = y.data
    length = @length
    if length!=y.length then return false
    for i in [0...length]
      if not trail.unify(xdata[i], ydata[i]) then return false
    true

  toString: () -> @data.toString()

# make unifable array
exports.uarray = uarray = (x) -> new UArray(x)

exports.Cons = class Cons
  constructor: (@head, @tail) ->

  getvalue: (trail, memo={}) ->
    head = @head; tail = @tail
    head1  = trail.getvalue(head, memo)
    tail1  = trail.getvalue(tail, memo)
    if head1 is head and tail1 is tail then @
    else new Cons(head1, tail1)

  unify: (y, trail) ->
   if y not instanceof Cons then false
   else if not trail.unify(@head, y.head) then false
   else trail.unify(@tail, y.tail)

  flatString: () ->
    result = "#{@head}"
    tail = @tail
    if tail is null then null
    else if tail instanceof Cons
      result += ','
      result += tail.flatString()
    else result += tail.toString()
    result

  toString: () -> "cons(#{@head}, #{@tail})"

# cons, like pair in lisp
exports.cons = (x, y) -> new Cons(x, y)

# conslist, like list in lisp
exports.conslist = (args...) ->
  result = null
  for i in [args.length-1..0] by -1
    result = new Cons([args[i], result])
  result

# make unifiable array or unifiable object
exports.unifiable = (x) ->
  if _.isArray(x) then new UArray(x)
  else if _.isObject(x) then new UObject(x)
  else x

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

exports.BindingError = class BindingError extends Error
exports.TypeError = class TypeError extends Error
exports.ExpressionError = class ExpressionError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error

# solver's status is set to UNKNOWN when start to solve, <br/>
#  if solver successfully run to solver'last continuation, status is set SUCCESS,<br/>
#  else if solver run to solver's failcont, status is set to FAIL.
exports.SUCCESS = 1
exports.UNKNOWN = 0
exports.FAIL = -1
exports.status = exports.UNKNOWN

exports.debug = debug = (items...) ->
  console.log(((for x in items
      if (x not instanceof Function)
        s = x.toString()
        if s=='[object Object]' then JSON.stringify(x) else s
      else '[Function]') )...)

#require("./builtins/general") <br/>
#require("./builtins/lisp") <br/>
#require("./builtins/logic")  <br/>
#require("./builtins/parser")

# * **todo**: compile
# * \#an idea: direct compile by function and compile to function?
# * **todo**: optimazation: partial evaluation?
# * **nottodo**: variable's applyCont:: canceled. lisp1 should be good.
# * **nottodo**: Apply's applyCont:: lisp1 should be good.
