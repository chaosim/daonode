# ##dao
# ###a functional logic sover, with builtin parser.
# continuation pass style, two continuations, one for succeed, one for fail and backtracking. <br/>

# #### what's new in 0.1.10
# uobject <br/>
# uarray <br/>

_ = require('underscore')

# * **todo**: compile
# * \#an idea: direct compile by function and compile to function?
# * **todo**: optimazation: partial evaluation?
# * **nottodo**: variable's applyCont:: canceled. lisp1 should be good.
# * **nottodo**: Apply's applyCont:: lisp1 should be good.


# ####solve
# use this utlity to solve a dao expression exp<br/>
#cont: (v, solver) -> body # in coffeescript <br/>
#function(v, solver){ body } # in javascript<br/>
#when solver succeed at last, @cont is executed.<br/>
#failcont: (v, solver) -> body  # in coffeescript<br/>
#function(v, solver){ body } # in javascript<br/>
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
  # @failcont is for backtracking in logic operation
  # @state is mainly used in parsing.
  constructor: (@failcont=faildone, @state) ->
    # @trail is used to restore varibale's binding for backtracking multiple logic choices
    @trail=new Trail
    #@cutCont is used for cut like in prolog.
    @cutCont = @failcont
    #@catches is used for lisp style catch/throw
    @catches = {}
    # @exits is used for block/break
    @exits = {}
    # like above, @continues play with block/continue
    @continues = {}
    # when @done is true, stop the the trampoline loop on continuation.
    @done = false

  # in callcc, callfc, callcs, the solver is needed to be cloned.
  clone: () ->
    state = @state
    if state? then state = state.slice?(0) or state.copy?() or state.clone?() or state
    result = new @constructor(@failcont, @trail.copy(), state)
    result.cutCont = @cutCont
    result.catches = _.extend({}, @catches)
    result.exits = _.extend({}, @exits)
    result.continues = _.extend({}, @continues)
    result

  # use this solver to solve exp, cont=done is the succeed continuation.
  solve: (exp, cont = done) ->
    # first generate the continuation to get start.
    cont = @cont(exp, cont or done)
    # and then run the trampoline loop on continuation.
    @run(cont)

  # run the trampoline from cont until @done is true.
  run: (cont) ->
    value = null
    solver = @
    while not solver.done
      [cont, value, solver] = cont(value, solver)
    value

  # generate the continuation to get start with.
  cont: (exp, cont) -> exp?.cont?(@, cont) or ((v, solver) -> cont(exp, solver))

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else @cont(exps[0], @expsCont(exps[1...], cont))

  # evaluate an array of expression to a array.
  argsCont: (args, cont) ->
    length = args.length
    solver = @
    # switch is an optimization for speed on frequent cases.
    switch length
      when 0
        (v, solver) -> cont([], solver)
      when 1
        cont0 = (v, solver) -> cont([v], solver)
        solver.cont(args[0],cont0)
      when 2
        arg0 = null
        _cont1 = (arg1, solver) -> cont([arg0, arg1], solver)
        cont1 = solver.cont(args[1], _cont1)
        cont0 = (v, solver) -> arg0 = v; cont1(null, solver)
        solver.cont(args[0], cont0)
      when 3
        arg0 = null; arg1 = null
        _cont2 = (arg2, solver) -> cont([arg0, arg1, arg2], solver)
        cont2 = solver.cont(args[2], _cont2)
        _cont1 = (v, solver) -> arg1 = v; cont2(null, solver)
        cont1 = solver.cont(args[1], _cont1)
        cont0 = (v, solver) -> arg0 = v; cont1(null, solver)
        solver.cont(args[0], cont0)
      when 4
        arg0 = null; arg1 = null; arg2 = null
        _cont3 = (arg3, solver) -> cont([arg0, arg1, arg2, arg3], solver)
        cont3 = solver.cont(args[3], _cont3)
        _cont2 = (v, solver) -> arg2 = v; cont3(null, solver)
        cont2 = solver.cont(args[2], _cont2)
        _cont1 = (v, solver) -> arg1 = v; cont2(null, solver)
        cont1 = solver.cont(args[1], _cont1)
        cont0 = (v, solver) -> arg0 = v; cont1(null, solver)
        solver.cont(args[0], cont0)
      when 5
        arg0 = null; arg1 = null; arg2 = null; arg3 = null
        _cont4 = (arg4, solver) -> cont([arg0, arg1, arg2, arg3, arg4], solver)
        cont4 = solver.cont(args[4], _cont4)
        _cont3 = (v, solver) -> arg3 = v; cont4(null, solver)
        cont3 = solver.cont(args[3], _cont3)
        _cont2 = (v, solver) -> arg2 = v; cont3(null, solver)
        cont2 = solver.cont(args[2], _cont2)
        _cont1 = (v, solver) -> arg1 = v; cont2(null, solver)
        cont1 = solver.cont(args[1], _cont1)
        cont0 = (v, solver) -> arg0 = v; cont1(null, solver)
        solver.cont(args[0], cont0)
      when 6
        arg0 = null; arg1 = null; arg2 = null; arg3 = null; arg4 = null
        _cont5 = (arg5, solver) -> cont([arg0, arg1, arg2, arg3, arg4, arg5], solver)
        cont5 = solver.cont(args[5], _cont5)
        _cont4 = (v, solver) -> arg4 = v; cont5(null, solver)
        cont4 = solver.cont(args[4], _cont4)
        _cont3 = (v, solver) -> arg3 = v; cont4(null, solver)
        cont3 = solver.cont(args[3], _cont3)
        _cont2 = (v, solver) -> arg2 = v; cont3(null, solver)
        cont2 = solver.cont(args[2], _cont2)
        _cont1 = (v, solver) -> arg1 = v; cont2(null, solver)
        cont1 = solver.cont(args[1], _cont1)
        cont0 = (v, solver) -> arg0 = v; cont1(null, solver)
        solver.cont(args[0], cont0)
      when 7
        arg0 = null; arg1 = null; arg2 = null; arg3 = null; arg4 = null; arg5 = null
        _cont6 = (arg6, solver) -> cont([arg0, arg1, arg2, arg3, arg4, arg5, arg6], solver)
        cont6 = solver.cont(args[6], _cont6)
        _cont5 = (v, solver) -> arg5 = v; cont6(null, solver)
        cont5 = solver.cont(args[5], _cont5)
        _cont4 = (v, solver) -> arg4 = v; cont5(null, solver)
        cont4 = solver.cont(args[4], _cont4)
        _cont3 = (v, solver) -> arg3 = v; cont4(null, solver)
        cont3 = solver.cont(args[3], _cont3)
        _cont2 = (v, solver) -> arg2 = v; cont3(null, solver)
        cont2 = solver.cont(args[2], _cont2)
        _cont1 = (v, solver) -> arg1 = v; cont2(null, solver)
        cont1 = solver.cont(args[1], _cont1)
        cont0 = (v, solver) -> arg0 = v; cont1(null, solver)
        solver.cont(args[0], cont0)
      else
        params = []
        for i in [args.length-1..0] by -1
          cont = do (i=i, cont=cont) ->
            _cont = (argi, solver) ->  (params.push(argi); cont(params, solver))
            solver.cont(args[i], _cont)
        cont

  # used by lisp style quasiquote, unquote, unquoteSlice
  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v, solver) -> cont(exp, solver))

  # an utility that is useful for some logic builtins<br/>
  # when backtracking, execute fun at first, and then go to original failcont
  appendFailcont: (fun) ->
    trail = @trail
    @trail = new Trail
    state = @state
    fc = @failcont
    @failcont = (v, solver) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc;
      fun(v, solver)

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
exports.done = done =(v, solver) ->
  solver.done = true
  exports.status = exports.SUCCESS
  [null, solver.trail.getvalue(v), solver]

# default stop continuation when fail
exports.faildone = faildone = (v, solver) ->
  solver.done = true
  exports.status = exports.FAIL
  [null, solver.trail.getvalue(v), solver]

# record the trail for variable binding <br/>
#  when multiple choices exist, a new Trail for current branch is constructored, <br/>
#  when backtracking, undo the trail to restore the previous variable binding
Trail = class exports.Trail
  constructor: (@data={}) ->
  copy: () -> new Trail(_.extend({},@data))
  set: (vari, value) ->
    if not @data.hasOwnProperty(vari.name)
      @data[vari.name] = [vari, value]

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

  cont: (solver, cont) -> (v, solver) => cont(@deref(solver.trail), solver)

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
  cont:(solver, cont) -> (v, solver) => cont(@binding, solver)
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
      return  solver.cont(@args[0], (v, solver) -> cont(v, solver))
    else if @caller.name is "unquoteSlice"
      # use the flag class UnquoteSliceValue to find unquoteSlice expression
      return solver.cont(@args[0], (v, solver) -> cont(new UnquoteSliceValue(v), solver))
    params = []
    cont = do (cont=cont) => ((v, solver) => [cont, new @constructor(@caller, params), solver])
    args = @args
    for i in [args.length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        solver.quasiquote(args[i], (v, solver) ->
          if v instanceof UnquoteSliceValue
            for x in v.value then params.push x
          else params.push(v);
          cont(null, solver))
    cont

# A flag class is used to process unquoteSlice
UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

# #### class Command
# dao command that can be applied <br/>
#  Special, Fun, Macro, Proc is subclass of Command.
Command = class exports.Command
  @directRun = false
  @done = (v, solver) -> (solver.done = true; [null, solver.trail.getvalue(v), solver])
  @faildone = (v, solver) -> (solver.done = true; [null, solver.trail.getvalue(v), solver])
  constructor: (@fun, @name, @arity) ->
    @callable = (args...) =>
      applied = new exports.Apply(@, args)
      if Command.directRun
        result = Command.globalSolver.solve(applied, Command.done)
        Command.globalSolver.done = false
        result
      else applied
    @callable.arity = @arity

  register: (exports) -> exports[@name] = @callable
  toString: () -> @name

commandMaker = (klass) -> (arity, name_or_fun, fun) ->
  if not _.isNumber(arity) and arity isnt null and not _.isArray(arity) then throw new ArgumentError(arity)
  (if fun? then new klass(fun, name_or_fun, arity) else new klass(name_or_fun, 'noname', arity)).callable

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
#  exports.fail = special(0, 'fail', (solver, cont) -> (v, solver) -> solver.failcont(v, solver))() #coffescript <br/>
#  exports.fail = special(0, 'fail', function(solver, cont) { # javascript <br/>
#    return function(v, solver) { <br/>
#      return solver.failcont(v, solver);<br/>
#    }; <br/>
#  })();<br/>
#
exports.special = special = commandMaker(exports.Special)

# KISS: to keep it simple, not to implmenting the applyCont in Var and Apply<br/>
# call goal with args...
exports.call = special(-1, 'call', (solver, cont, goal, args...) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null, solver))
  solver.cont(goal, (v, solver) -> goal1 = goal; argsCont(null, solver)))

# apply goal with args
exports.apply  = special(2, 'apply', (solver, cont, goal, args) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null, solver))
  solver.cont(goal, (v, solver) -> goal1 = goal; argsCont(null, solver)))

# Fun evaluate its arguments, and return the result to fun(params...) to cont directly.
class exports.Fun extends exports.Command
  applyCont: (solver, cont, args) ->  solver.argsCont(args, (params, solver) => [cont, @fun(params...), solver])

# generate an instance of Fun from a function <br/>
#  example:  <br/>
#  add = fun((x, y) -> x+y ) # coffeescript <br/>
#  add = fun(function(x,y){ return x+y; } # javascript <br/>
exports.fun = commandMaker(exports.Fun)

# Fun2 evaluate its arguments, and evaluate the result of fun(params...) again
class exports.Fun2 extends exports.Command
  applyCont: (solver, cont, args) ->
    solver.argsCont(args, (params, solver) => solver.cont(@fun(params...), cont)(params, solver))

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
    idMap =  Macro.idMap
    id = @id
    if not idMap[id] then idMap[id] = true; result = solver.cont(exp, cont); delete idMap[id]; result
    else (v, solver) ->  delete idMap[id]; solver.cont(exp, cont)(v, solver)

# generate a instance of Macro from a function <br/>
#  example:   <br/>
#  orpm = fun((x, y) -> orp(x,y ) # coffeescript<br/>
#  orpm = fun(function(x,y){  return orp(x,y ); } # javascript
exports.macro = commandMaker(exports.Macro)

# In Proc's function, the dao's expressions can be directly evaluated
class exports.Proc extends exports.Command
  applyCont:  (solver, cont, args) ->
    (v, solver) =>
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
          solver.argsCont(args, (params, solver) -> [solver.cont(cmd(params...), cont), params, solver]))

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

class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

class BindingError extends Error
class TypeError extends Error
class ExpressionError extends Error
class ArgumentError extends Error
class ArityError extends Error

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
