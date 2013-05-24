_ = require('underscore')

### dao: a functional logic sover, with builtin parser.
  continuation pass style, two continuations, one for succeed, one for fail and backtracking. ###

###
todo: compile
an idea: direct compile by function and compile to function?
todo: optimazation: partial evaluation?
nottodo: variable's apply_cont:: canceled. lisp1 should be good.
nottodo: Apply's apply_cont:: lisp1 should be good.
###

### the utility function: use this utlity to solve an dao expression @exp
  @cont: (v, solver) -> body # in coffeescript
         function(v, solver){ body } # in javascript
    # when solver succeed at last, @cont isexecuted.
  @failcont: (v, solver) -> body  # in coffeescript
         function(v, solver){ body } # in javascript
     # when solver fails at last, @failcont is executed.
  @state: the state of solver, mainly used for parsing
   ###
exports.solve = (exp, cont=done, failcont=faildone, state) ->
  exports.status = exports.UNKNOWN
  exports.solver(failcont, state).solve(exp, cont)

exports.solver = (failcont = faildone, state) -> new exports.Solver(failcont, state)

### the solver for dao ###
class exports.Solver
  constructor: (@failcont=faildone, @state) ->
    @trail=new Trail  # used  to restore varibale's binding. for backtracking multiple logic choices
    @cutCont = @failcont # used for cut like in prolog.
    @catches = {}  # used for lisp style catch/throw
    @exits = {}  # used for block/break
    @continues = {} # like above, play with block/continue
    @done = false # stop flag for the trampoline loop.

  ### in callcc, callfc, callcs, the solver is needed to be cloned.###
  clone: () ->
    state = @state
    if state? then state = state.slice?(0) or state.copy?() or state.clone?() or state
    result = new @constructor(@failcont, @trail.copy(), state)
    result.cutCont = @cutCont
    result.catches = _.extend({}, @catches)
    result.exits = _.extend({}, @exits)
    result.continues = _.extend({}, @continues)
    result

  ### use this solver to solve @exp, @cont=done is the succeed continuation.###
  solve: (exp, cont = done) ->
    cont = @cont(exp, cont or done)  # first generate the continuation to get start.
    @run(cont) # the trampoline loop

  ### the trampoline from cont until solver.done is true. ###
  run: (cont) ->
    value = null
    solver = @
    while not solver.done
      [cont, value, solver] = cont(value, solver)
    value

  ### generate the continuation to get start ###
  cont: (exp, cont) -> exp?.cont?(@, cont) or ((v, solver) -> cont(exp, solver))

  ### used for lisp.begin, logic.andp, generate the continuation for an expression array ###
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else @cont(exps[0], @expsCont(exps[1...], cont))

  ### evaluate an expression array to a array. ###
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

  ### used by lisp style quasiquote, unquote, unquoteSlice ###
  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v, solver) -> cont(exp, solver))

  ### an utility that is useful for some logic builtins
      when backtracking, execute fun at first, and then go to original failcont ###
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

  ### pushCatch/popCatch/findCatch: utlities for lisp style catch/throw ###
  pushCatch: (value, cont) ->
    catches = @catches[value] ?= []
    catches.push(cont)

  popCatch: (value) -> catches = @catches[value]; catches.pop(); if catches.length is 0 then delete @catches[value]

  findCatch: (value) ->
    catches = @catches[value]
    if not catches? or catches.length is 0 then throw new NotCatched
    catches[catches.length-1]

  ### utility for lisp style unwind-protect, play with block/break/continue, catch/throw and lisp.protect ###
  protect: (fun) -> fun

### default last continuation when succeed ###
exports.done = done =(v, solver) ->
  solver.done = true
  exports.status = exports.SUCCESS
  [null, solver.trail.getvalue(v), solver]

### default last continuation when fail ###
exports.faildone = faildone = (v, solver) ->
  solver.done = true
  exports.status = exports.FAIL
  [null, solver.trail.getvalue(v), solver]

MAXBINDINGCHAINLENGTH = 200 # to break cylylic binding

### record the trail for variable binding
  when multiple choices exist, a new Trail for current branch is constructored,
  when backtracking, undo the trail to restore the previous variable binding ###
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

### Var for logic bindings, used in unify, lisp.assign, inc/dec, parser operation, etc. ###
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

### in macro, we need unique var to avoid conflicting ###
nameToIndexMap = {}
exports.newVar = (name='v') ->
  index = nameToIndexMap[name]? or 1
  nameToIndexMap[name] = index+1
  return new Var(name+index)

### DummyVar never fail when it need unify. see tests about any/some/times for examples ###
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

### the apply to some Command(special, fun, macro, proc, etc) ###
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

### flag class to process unquoteSlice ###
UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

### dao command that can be applied
  Special, Fun, Macro, Proc is subclass of Command. ###
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

### Speical knows solver and cont, with them the special function has full control of things. ###
class exports.Special extends exports.Command
  apply_cont: (solver, cont, args) -> @fun(solver, cont, args...)

### generate an instance of Special from a function
  example:
  begin = special(null, 'begin', (solver, cont, exps...) -> solver.expsCont(exps, cont))  # coffeescript
  exports.begin = special(null, 'begin', function() { # javascript
    var cont, exps, solver;

    solver = arguments[0], cont = arguments[1], exps = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    return solver.expsCont(exps, cont);
  });
  exports.fail = special(0, 'fail', (solver, cont) -> (v, solver) -> solver.failcont(v, solver))() #coffescript
  exports.fail = special(0, 'fail', function(solver, cont) { # javascript
    return function(v, solver) {
      return solver.failcont(v, solver);
    };
  })();
   ###
exports.special = special = commandMaker(exports.Special)

### KISS: to keep it simple, not to implmenting the apply_cont in Var and Apply ###
###  call goal with args...###
exports.call = special(-1, 'call', (solver, cont, goal, args...) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null, solver))
  solver.cont(goal, (v, solver) -> goal1 = goal; argsCont(null, solver)))

### apply goal with args ###
exports.apply  = special(2, 'apply', (solver, cont, goal, args) ->
  goal1 = null
  argsCont =  solver.argsCont(args, (params,  solver) ->
    solver.cont(goal1(params...), cont)(null, solver))
  solver.cont(goal, (v, solver) -> goal1 = goal; argsCont(null, solver)))

### Fun evaluate its arguments, and return the result to fun(params...) to cont directly. ###
class exports.Fun extends exports.Command
  apply_cont: (solver, cont, args) ->  solver.argsCont(args, (params, solver) => [cont, @fun(params...), solver])

### generate an instance of Fun from a function
  example:
  add = fun((x, y) -> x+y ) # coffeescript
  add = fun(function(x,y){ return x+y; } # javascript
  ###
exports.fun = commandMaker(exports.Fun)

### similar to lisp'macro, Macro does NOT evaluate its arguments, but evaluate the result to fun(args). ###
class exports.Macro extends exports.Command
  apply_cont: (solver, cont, args) -> solver.cont(@fun(args...), cont)

### generate a instance of Macro from a function
  example:
  orpm = fun((x, y) -> orp(x,y ) # coffeescript
  orpm = fun(function(x,y){  return orp(x,y ); } # javascript
  ###
exports.macro = commandMaker(exports.Macro)

### In Porc's function, the dao's expressions can be directed evaluated ###
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
  ### evaluate the arguments of a command before execute it.
    with tofun, Special and Macro can behaviour like a Fun.
    cmd can be an instance of subclass of Command,
     especially macro(macro don't eval its arguments)
     and specials that don't eval their arguments. ###
  unless cmd? then (cmd = name; name = 'noname')
  special(cmd.arity, name, (solver, cont, args...) ->
          solver.argsCont(args, (params, solver) -> [solver.cont(cmd(params...), cont), params, solver]))

class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

class BindingError extends Error
class TypeError extends Error
class ExpressionError extends Error
class ArgumentError extends Error
class ArityError extends Error

### solver's status is set to UNKNOWN when start to solve,
  if solver successfully run to solver'last continuation, status is set SUCCESS,
  else if solver run to solver's failcont, status is set to FAIL.###
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

#require("./builtins/general")
#require("./builtins/lisp")
#require("./builtins/logic")
#require("./builtins/parser")
