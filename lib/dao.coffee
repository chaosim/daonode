# ##dao
# ###a functional logic solver, with builtin parser.
# continuation pass style, two continuations, one for succeed, one for fail and backtracking. <br/>

# #### what's new 0.1.11
# findall: get result by template
# bug fix: special arity checking take account of (solver, cont, args...)

# #### what's new in 0.1.10
# uobject <br/>
# uarray <br/>
# cons

_ = require('underscore')

# ####solve
# use this utlity to solve a dao expression exp<br/>
#cont: (v) -> body # in coffeescript <br/>
#function(v){ body } # in javascript<br/>
#when solver succeed at last, @cont is executed.<br/>
#failcont: (v) -> body  # in coffeescript<br/>
#function(v){ body } # in javascript<br/>
#when solver fails at last, @failcont is executed.<br/>
#state: the state of solver, mainly used for parsing <br/>

exports.solve = (exp, cont=done, failcont=faildone, state) ->
  exports.status = exports.UNKNOWN
  exports.solver(failcont, state).solve(exp, cont)

# ####solver
# utility for new Solver
exports.solver = (failcont = faildone, state) -> new exports.Solver(failcont, state)

# ####class Solver
# the solver for dao expression
class exports.Solver
  # failcont is for backtracking in logic operation
  # state is mainly used in parsing.
  constructor: (@faildone=faildone, @state) ->
    # @trail is used to restore varibale's binding for backtracking multiple logic choices
    @failcont = @faildone
    @trail=new Trail
    #@cutCont is used for cut like in prolog.
    @cutCont = @failcont
    #@catches is used for lisp style catch/throw
    @catches = {}
    # @exits is used for block/break
    @exits = {}
    # like above, @continues play with block/continue
    @continues = {}

  # in callcc, callfc, callcs, the solver is needed to be cloned.
  clone: () ->
    result = {}
    result.constructor = @constructor
    result:: = @::
    result.faildone = @faildone
    result.failcont = @failcont
    result.trail = @trail.copy()
    state = @state
    if state? then state = state.slice?(0) or state.copy?() or state.clone?() or state
    result.cutCont = @cutCont
    result.catches = _.extend({}, @catches)
    result.exits = _.extend({}, @exits)
    result.continues = _.extend({}, @continues)
    result.done = @done
    result.faildone = @faildone
    result

  # use this solver to solve exp, cont=done is the succeed continuation.
  solve: (exp, toCont = done) ->
    @done = toCont
    # first generate the continuation to get start.
    fromCont = @cont(exp, toCont)
    # and then run the trampoline loop on continuation.
    @trail.getvalue(@run(null, fromCont, toCont))

  # run the trampoline from cont until @done is true.
  run: (value, cont, toCont) ->
    if not toCont then toCont = @done
    while 1
      [cont, value] = cont(value)
      if cont is toCont then exports.status = exports.SUCCESS; return value
      if cont is @faildone then  exports.status = exports.FAIL; return value

  # generate the continuation to get start with.
  cont: (exp, cont) -> exp?.cont?(@, cont) or ((v) -> cont(exp))

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else @cont(exps[0], @expsCont(exps[1...], cont))

  # evaluate an array of expression to a array.
  argsCont: (args, cont) ->
    length = args.length
    # switch is an optimization for speed on frequent cases.
    switch length
      when 0
        (v) -> cont([])
      when 1
        cont0 = (v) -> cont([v])
        @cont(args[0],cont0)
      when 2
        arg0 = null
        _cont1 = (arg1) -> cont([arg0, arg1])
        cont1 = @cont(args[1], _cont1)
        cont0 = (v) -> arg0 = v; cont1(null)
        @cont(args[0], cont0)
      when 3
        arg0 = null; arg1 = null
        _cont2 = (arg2) -> cont([arg0, arg1, arg2])
        cont2 = @cont(args[2], _cont2)
        _cont1 = (v) -> arg1 = v; cont2(null)
        cont1 = @cont(args[1], _cont1)
        cont0 = (v) -> arg0 = v; cont1(null)
        @cont(args[0], cont0)
      when 4
        arg0 = null; arg1 = null; arg2 = null
        _cont3 = (arg3) -> cont([arg0, arg1, arg2, arg3])
        cont3 = @cont(args[3], _cont3)
        _cont2 = (v) -> arg2 = v; cont3(null)
        cont2 = @cont(args[2], _cont2)
        _cont1 = (v) -> arg1 = v; cont2(null)
        cont1 = @cont(args[1], _cont1)
        cont0 = (v) -> arg0 = v; cont1(null)
        @cont(args[0], cont0)
      when 5
        arg0 = null; arg1 = null; arg2 = null; arg3 = null
        _cont4 = (arg4) -> cont([arg0, arg1, arg2, arg3, arg4])
        cont4 = @cont(args[4], _cont4)
        _cont3 = (v) -> arg3 = v; cont4(null)
        cont3 = @cont(args[3], _cont3)
        _cont2 = (v) -> arg2 = v; cont3(null)
        cont2 = @cont(args[2], _cont2)
        _cont1 = (v) -> arg1 = v; cont2(null)
        cont1 = @cont(args[1], _cont1)
        cont0 = (v) -> arg0 = v; cont1(null)
        @cont(args[0], cont0)
      when 6
        arg0 = null; arg1 = null; arg2 = null; arg3 = null; arg4 = null
        _cont5 = (arg5) -> cont([arg0, arg1, arg2, arg3, arg4, arg5])
        cont5 = @cont(args[5], _cont5)
        _cont4 = (v) -> arg4 = v; cont5(null)
        cont4 = @cont(args[4], _cont4)
        _cont3 = (v) -> arg3 = v; cont4(null)
        cont3 = @cont(args[3], _cont3)
        _cont2 = (v) -> arg2 = v; cont3(null)
        cont2 = @cont(args[2], _cont2)
        _cont1 = (v) -> arg1 = v; cont2(null)
        cont1 = @cont(args[1], _cont1)
        cont0 = (v) -> arg0 = v; cont1(null)
        @cont(args[0], cont0)
      when 7
        arg0 = null; arg1 = null; arg2 = null; arg3 = null; arg4 = null; arg5 = null
        _cont6 = (arg6) -> cont([arg0, arg1, arg2, arg3, arg4, arg5, arg6])
        cont6 = @cont(args[6], _cont6)
        _cont5 = (v) -> arg5 = v; cont6(null)
        cont5 = @cont(args[5], _cont5)
        _cont4 = (v) -> arg4 = v; cont5(null)
        cont4 = @cont(args[4], _cont4)
        _cont3 = (v) -> arg3 = v; cont4(null)
        cont3 = @cont(args[3], _cont3)
        _cont2 = (v) -> arg2 = v; cont3(null)
        cont2 = @cont(args[2], _cont2)
        _cont1 = (v) -> arg1 = v; cont2(null)
        cont1 = @cont(args[1], _cont1)
        cont0 = (v) -> arg0 = v; cont1(null)
        @cont(args[0], cont0)
      else
        params = []
        solver = @
        for i in [args.length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            _cont = (argi) ->  (params.push(argi); cont(params))
            solver.cont(args[i], _cont)
        cont

  # used by lisp style quasiquote, unquote, unquoteSlice
  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v) -> cont(exp))

  # an utility that is useful for some logic builtins<br/>
  # when backtracking, execute fun at first, and then go to original failcont
  appendFailcont: (fun) ->
    trail = @trail
    @trail = new Trail
    state = @state
    fc = @failcont
    @failcont = (v) ->
      @trail.undo()
      @trail = trail
      @state = state
      @failcont = fc;
      fun(v)

  # pushCatch/popCatch/findCatch: utlities for lisp style catch/throw
  pushCatch: (value, cont) ->
    catches = @catches[value] ?= []
    catches.push(cont)

  popCatch: (value) -> catches = @catches[value]; catches.pop(); if catches.length is 0 then delete @catches[value]

  findCatch: (value) ->
    catches = @catches[value]
    if not catches? or catches.length is 0 then throw new NotCatched
    catches[catches.length-1]

  # utility for lisp style unwind-protect, play with block/break/continue, catch/throw and lisp.protect
  protect: (fun) -> fun

# default stop continuation when succeed
exports.done = done =(v) -> [done, v]

# default stop continuation when fail
exports.faildone = faildone = (v) -> [faildone, v]

# record the trail for variable binding <br/>
#  when multiple choices exist, a new Trail for current branch is constructored, <br/>
#  when backtracking, undo the trail to restore the previous variable binding
# todo: when variable is new constrctored in current branch, it could not be recorded.
Trail = class exports.Trail
  constructor: (@data={}) ->
  copy: () -> new Trail(_.extend({},@data))
  set: (vari, value) ->
    data = @data
    if not data.hasOwnProperty(vari.name)
      data[vari.name] = [vari, value]

  undo: () -> for nam, pair of  @data
      vari = pair[0]
      value = pair[1]
      vari.binding = value

  deref: (x) -> x?.deref?(@) or x
  getvalue: (x, memo={}) ->
    getvalue =  x?.getvalue
    if getvalue then getvalue.call(x, @, memo)
    else x
  unify: (x, y) ->
    x = @deref(x); y = @deref(y)
    if x instanceof Var then @set(x, x.binding); x.binding = y; true;
    else if y instanceof Var then @set(y, y.binding); y.binding = x; true;
    else x?.unify?(y, @) or y?.unify?(x, @) or (x is y)

# ####class Var
# Var for logic bindings, used in unify, lisp.assign, inc/dec, parser operation, etc.
Var = class exports.Var
  constructor: (@name, @binding = @) ->
  deref: (trail) ->
    v = @
    next = @binding
    if next is @ or next not instanceof Var then next
    else
      chains = [v]
      length = 1
      while 1
        chains.push(next)
        v = next; next = v.binding
        length++
        if next is v
          for i in [0...chains.length-2]
            x = chains[i]
            x.binding = next
            trail.set(x, chains[i+1])
          return next
        else if next not instanceof Var
          for i in [0...chains.length-1]
            x = chains[i]
            x.binding = next
            trail.set(x, chains[i+1])
          return next

  bind: (value, trail) ->
    trail.set(@, @binding)
    @binding = trail.deref(value)

  getvalue: (trail, memo={}) ->
    name = @name
    if memo.hasOwnProperty(name) then return memo[name]
    result = @deref(trail)
    if result instanceof Var
      memo[name] = result
      result
    else
      result = trail.getvalue(result, memo)
      memo[name] = result
      result

  cont: (solver, cont) -> (v) => cont(@deref(solver.trail))

  # nottodo: variable's applyCont:: canceled. lisp1 should be good.

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
  cont:(solver, cont) -> (v) => cont(@binding)
  deref: (trail) -> @
  getvalue: (trail, memo={}) ->
    name = @name
    if memo.hasOwnProperty(name) then return memo[name]
    result = @binding
    if result is @
      memo[name] = result
      result
    else
      result = trail.getvalue(result, memo)
      memo[name] = result
      result

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
  cont: (solver, cont) -> @caller.applyCont(solver, cont, @args)

  # play with lisp style quasiquote/unquote/unquoteSlice
  quasiquote:  (solver, cont) ->
    if @caller.name is "unquote"
      return  solver.cont(@args[0], (v) -> cont(v))
    else if @caller.name is "unquoteSlice"
      # use the flag class UnquoteSliceValue to find unquoteSlice expression
      return solver.cont(@args[0], (v) -> cont(new UnquoteSliceValue(v)))
    params = []
    cont = do (cont=cont) => ((v) => [cont, new @constructor(@caller, params)])
    args = @args
    for i in [args.length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        solver.quasiquote(args[i], (v) ->
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
        result = Command.globalSolver.solve(applied, done)
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
    # bugfix(0.1.11): Special has special fun's signature (solver, cont, args...)
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

# Speical knows solver and cont, with them the special function has full control of things.
class exports.Special extends exports.Command
  applyCont: (solver, cont, args) -> @fun(solver, cont, args...)

# generate an instance of Special from a function <br/>
#  example:<br/>
#  begin = special(null, 'begin', (solver, cont, exps...) -> solver.expsCont(exps, cont))  # coffeescript <br/>
#  exports.begin = special(null, 'begin', function() { # javascript <br/>
#    var cont, exps, solver; <br/>
#    <br/>
#    solver = arguments[0], cont = arguments[1], exps = 3 <= arguments.length ? __slice.call(arguments, 2) : [];<br/>
#    return solver.expsCont(exps, cont);<br/>
#  });<br/>
#  exports.fail = special(0, 'fail', (solver, cont) -> (v) -> solver.failcont(v))() #coffescript <br/>
#  exports.fail = special(0, 'fail', function(solver, cont) { # javascript <br/>
#    return function(v) { <br/>
#      return solver.failcont(v);<br/>
#    }; <br/>
#  })();<br/>
#
exports.special = special = commandMaker(exports.Special)

# KISS: to keep it simple, not to implmenting the applyCont in Var and Apply<br/>
# call goal with args...
exports.call = special(-1, 'call', (solver, cont, goal, args...) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null))
  solver.cont(goal, (v) -> goal1 = goal; argsCont(null)))

# apply goal with args
exports.apply  = special(2, 'apply', (solver, cont, goal, args) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null))
  solver.cont(goal, (v) -> goal1 = goal; argsCont(null)))

# Fun evaluate its arguments, and return the result to fun(params...) to cont directly.
class exports.Fun extends exports.Command
  applyCont: (solver, cont, args) ->  solver.argsCont(args, (params) => [cont, @fun(params...)])

# generate an instance of Fun from a function <br/>
#  example:  <br/>
#  add = fun((x, y) -> x+y ) # coffeescript <br/>
#  add = fun(function(x,y){ return x+y; } # javascript <br/>
exports.fun = commandMaker(exports.Fun)

# Fun2 evaluate its arguments, and evaluate the result of fun(params...) again
class exports.Fun2 extends exports.Command
  applyCont: (solver, cont, args) ->
    solver.argsCont(args, (params) => [solver.cont(@fun(params...), cont), params])

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

  applyCont: (solver, cont, args) ->
    exp = @fun(args...)
#    solver.cont(exp, cont)
    # prevent max recursive macro extend
    idMap =  Macro.idMap
    id = @id
    if not idMap[id] then idMap[id] = true; result = solver.cont(exp, cont); delete idMap[id]; result
    else (v) ->  delete idMap[id]; solver.cont(exp, cont)(v)

# generate a instance of Macro from a function <br/>
#  example:   <br/>
#  orpm = fun((x, y) -> orp(x,y ) # coffeescript<br/>
#  orpm = fun(function(x,y){  return orp(x,y ); } # javascript
exports.macro = commandMaker(exports.Macro)

# In Proc's function, the dao's expressions can be directly evaluated
class exports.Proc extends exports.Command
  applyCont:  (solver, cont, args) ->
    (v) =>
      Command.directRun = true
      savedSolver = Command.globalSolver
      Command.globalSolver = solver
      result = @fun(args...)
      Command.globalSolver = savedSolver
      Command.directRun = false
      [cont, result,  solver]

exports.proc = commandMaker(exports.Proc)

exports.tofun = (name, cmd) ->
  # evaluate the arguments of a command before execute it<br/>.
#    with tofun, Special and Macro can behaviour like a Fun.<br/>
#    cmd can be an instance of subclass of Command, <br/>
#     especially macro(macro don't eval its arguments) <br/>
#     and specials that don't eval their arguments.
  unless cmd? then (cmd = name; name = 'noname')
  special(cmd.arity, name, (solver, cont, args...) ->
          solver.argsCont(args, (params) -> [solver.cont(cmd(params...), cont), params]))

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

exports.BindingError = class Error
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
