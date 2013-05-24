_ = require('underscore')

### dao: a functional logic sover, with builtin parser.
  continuation pass style, two continuations, one for succeed, one for fail and backtracking. ###

### todo: compile
an idea: direct compile by function and compile to function?
todo: optimazation: partial evaluation?
nottodo: variable's apply_cont:: canceled. lisp1 should be good.
nottodo: Apply's apply_cont:: lisp1 should be good.
###

exports.debug = debug = (items...) ->
  console.log((
      (for x in items
              if (x not instanceof Function)
                s = x.toString()
                if s=='[object Object]' then JSON.stringify(x) else s
              else '[Function]') )...)

class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

class BindingError extends Error
class TypeError extends Error
class ExpressionError extends Error
class ArgumentError extends Error
class ArityError extends Error

exports.checkArity1 = (args, n) ->
  if arguments.length isnt n then throw new ArityError(args)

exports.checkArity2 = (args, n) ->
  if arguments.length < n then throw new ArityError(args)

exports.checkArity3 = (args, arities...) ->
  if arguments.length not in arities then throw new ArityError(args)

exports.SUCCESS = 1
exports.UNKNOWN = 0
exports.FAIL = -1
exports.status = exports.UNKNOWN

exports.done = done =(v, solver) ->
  solver.done = true
  exports.status = exports.SUCCESS
  [null, solver.trail.getvalue(v), solver]

exports.faildone = faildone = (v, solver) ->
  solver.done = true
  exports.status = exports.FAIL
  [null, solver.trail.getvalue(v), solver]

exports.solve = (exp, cont=done, failcont=faildone, trail=new Trail) ->
  exports.status = exports.UNKNOWN
  new exports.Solver(failcont, trail).solve(exp, cont)

exports.solver = (failcont = faildone, trail=new Trail, state) -> new exports.Solver(failcont, trail, state)

### the solver for dao ###
class exports.Solver
  constructor: (@failcont=faildone, @trail=new Trail, @state) ->
    @cutCont = @failcont
    @catches = {}
    @exits = {}
    @continues = {}
    @done = false

  clone: () ->
    state = @state
    if state? then state = state.slice?(0) or state.copy?() or state.clone?() or state
    result = new @constructor(@failcont, @trail.copy(), state)
    result.cutCont = @cutCont
    result.catches = _.extend({}, @catches)
    result.exits = _.extend({}, @exits)
    result.continues = _.extend({}, @continues)
    result

  solve: (exp, cont = done) ->
    cont = @cont(exp, cont or done)
    @run(cont)

  run: (cont) ->
    value = null
    solver = @
    while not solver.done
      [cont, value, solver] = cont(value, solver)
    value

  cont: (exp, cont) -> exp?.cont?(@, cont) or ((v, solver) -> cont(exp, solver))

  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v, solver) -> cont(exp, solver))

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

  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else @cont(exps[0], @expsCont(exps[1...], cont))

  argsCont: (args, cont) ->
    length = args.length
    solver = @
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

  pushCatch: (value, cont) ->
    catches = @catches[value] ?= []
    catches.push(cont)

  popCatch: (value) -> catches = @catches[value]; catches.pop(); if catches.length is 0 then delete @catches[value]

  findCatch: (value) ->
    catches = @catches[value]
    if not catches? or catches.length is 0 then throw new NotCatched
    catches[catches.length-1]

  protect: (fun) -> fun

MAXBINDINGCHAINLENGTH = 200 # to break cylylic binding

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
  getvalue: (x, chainslength=0) -> x?.getvalue?(@, chainslength) or x
  unify: (x, y) -> x?.unify?(y, @) or y?.unify?(x, @) or (x is y)

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
        else if length > MAXBINDINGCHAINLENGTH
          throw BindingError(v, "Binding chains is too long!")

  bind: (value, trail) ->
    trail.set(@, @binding)
    @binding = value

  unify: (y, trail) ->
    x = @deref(trail)
    y = trail.deref(y)
    if x instanceof exports.Var then (x.bind(y, trail); true)
    else if y instanceof exports.Var then (y.bind(x,  trail); true)
    else x._unify?(y, trail) or y._unify?(x, trail) or x is y

  _unify: (y, trail) -> @bind(y, trail); true

  getvalue: (trail, chainslength=0) ->
    result = @deref(trail)
    if result instanceof exports.Var then result
    else trail.getvalue(result, chainslength+1)

  cont: (solver, cont) -> (v, solver) => cont(@deref(solver.trail), solver)
  # nottodo: variable's apply_cont:: canceled. lisp1 should be good.

  toString:() -> "vari(#{@name})"

reElements = /\s*,\s*|\s+/

exports.vari = (name) -> new exports.Var(name)
exports.vars = (names) -> new Var(name) for name in split names,  reElements

nameToIndexMap = {}
exports.newVar = (name='v') ->
  index = nameToIndexMap[name]? or 1
  nameToIndexMap[name] = index+1
  return new Var(name+index)

exports.DummyVar = class DummyVar extends Var
  constructor: (name) -> @name = '_$'+name
  deref: (trail) -> @
  bind: (value, trail) -> @binding = value
  _unify: (y, trail) -> @binding = y; true
  getvalue: (trail, chainslength=1) ->
    result = @binding
    if result is @
    else if chainslength>MAXBINDINGCHAINLENGTH
      throw new BindingError(result, "Binding chains is too long!")
    else trail.getvalue(result, chainslength+1)

  # nottodo: variable's apply_cont:: canceled. lisp1 should be good.

exports.dummy = (name) -> new exports.DummyVar(name)
exports.dummies = (names) -> new DummyVar(name) for name in split names,  reElements

class exports.Apply
  constructor: (@caller, @args) ->
    # null: (...)
    # [2, 4]: (a, b), (a, b, c, d)
    # -1: (a, b...);   -2: (a, b, c...)
    # 1: (a);      3: (a, b, c)
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

  toString: -> "#{@caller}(#{@args.join(', ')})"

  cont: (solver, cont) -> @caller.apply_cont(solver, cont, @args)

  quasiquote:  (solver, cont) ->
    if @caller.name is "unquote"
      return  solver.cont(@args[0], (v, solver) -> cont(v, solver))
    else if @caller.name is "unquoteSlice"
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

UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

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

class exports.Special extends exports.Command
  apply_cont: (solver, cont, args) -> @fun(solver, cont, args...)

exports.special = special = commandMaker(exports.Special)

# to keep it simple, not to implmenting the apply_cont in Var and Apply
exports.call = special(-1, 'call', (solver, cont, goal, args...) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null, solver))
  solver.cont(goal, (v, solver) -> goal1 = goal; argsCont(null, solver)))

exports.apply  = special(2, 'apply', (solver, cont, goal, args) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null, solver))
  solver.cont(goal, (v, solver) -> goal1 = goal; argsCont(null, solver)))

class exports.Fun extends exports.Command
  apply_cont: (solver, cont, args) ->  solver.argsCont(args, (params, solver) => [cont, @fun(params...), solver])

exports.fun = commandMaker(exports.Fun)

class exports.Macro extends exports.Command
  apply_cont: (solver, cont, args) -> solver.cont(@fun(args...), cont)

exports.macro = commandMaker(exports.Macro)

class exports.Proc extends exports.Command
  apply_cont:  (solver, cont, args) ->
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
  # cmd can be an instance of subclass of Command, especially macro(macro don't eval its arguments)
  # and specials that don't eval their arguments.
  unless cmd? then (cmd = name; name = 'noname')
  special(cmd.arity, name, (solver, cont, args...) ->
          solver.argsCont(args, (params, solver) -> [solver.cont(cmd(params...), cont), params, solver]))

require("./builtins/general")
require("./builtins/lisp")
require("./builtins/logic")
require("./builtins/parser")
