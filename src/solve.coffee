_ = require('underscore')

exports.debug = debug = (items...) ->
  console.log((
      (for x in items
              if (x not instanceof Function)
                s = x.toString()
                if s=='[object Object]' then JSON.stringify(x) else s
              else '[Function]') )...)

exports.done = done =(v, solver) -> console.log("succeed!"); solver.done = true; [null, solver.trail.getvalue(v), solver]

exports.faildone = faildone =(v, solver) -> console.log("fail!"); solver.done = true;  [null, solver.trail.getvalue(v), solver]

exports.solve = (exp, trail=new Trail, cont = done, failcont = faildone) ->
  new exports.Solver(trail, failcont).solve(exp, cont)

exports.solver = (trail=new Trail, failcont = faildone, state) -> new exports.Solver(trail, failcont, state)

class exports.Solver
  constructor: (@trail=new exports.Trail, @failcont = faildone, @state) ->
    @cutCont = @failcont
    @catches = {}
    @exits = {}
    @continues = {}
    @done = false

  pushCatch: (value, cont) ->
    catches = @catches[value] ?= []
    catches.push(cont)

  popCatch: (value) -> catches = @catches[value]; catches.pop(); if catches.length is 0 then delete @catches[value]

  findCatch: (value) ->
    catches = @catches[value]
    if not catches? or catches.length is 0 then throw new NotCatched
    catches[catches.length-1]

  protect: (fun) -> fun

  cont: (exp, cont) -> exp?.cont?(@, cont) or ((v, solver) -> cont(exp, solver))

  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v, solver) -> cont(exp, solver))

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

  solve: (exp, cont = done) ->
    cont = @cont(exp, cont or done)
    value = null
    solver = @
    while not solver.done
      [cont, value, solver] = cont(value, solver)
    value

Trail = class exports.Trail
  constructor: (@data={}) ->
  set: (vari, value) ->  if not @data.hasOwnProperty(vari.name) then @data[vari.name] = [vari, value]
  undo: () -> for name, pair of @data then pair[0].binding = pair[1]
  deref: (x) -> x?.deref?(@) or x
  getvalue: (x) -> x?.getvalue?(@) or x
  unify: (x, y) -> x?.unify?(y, @) or y?.unify?(x, @) or (x is y)

Var = class exports.Var
  constructor: (@name, @binding = @) ->
  deref: (trail) ->
    v = @
    next = @binding
    if next is @ or next not instanceof Var then next
    else
      chains = [v]
      while 1
        chains.push(next)
        v = next; next = v.binding
        if next is v
          for i in [0...chains.length-2]
            x = chains[i]
            x.binding = next
            trail.set(x, chains[i+1])
          return next
        else if not next instanceof Var
          for i in [0...chains.length-1]
            x = chains[i]
            x.binding = next
            trail.set(x, chains[i+1])
          return next

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

  getvalue: (trail) ->
    result = @deref(trail)
    if result instanceof exports.Var then result
    else getvalue(result)

  cont: (solver, cont) -> (v, solver) => cont(@deref(solver.trail), solver)

  toString:() -> "vari(#{@name})"

reElements = /\s*,\s*|\s+/

exports.vari = (name) -> new exports.Var(name)
exports.vars = (names) -> new Var(name) for name in split names,  reElements

exports.DummyVar = class DummyVar extends Var
  deref: (trail) -> @
  bind: (value, trail) -> @binding = value
  _unify: (y, trail) -> @binding = y; true
  getvalue: (trail) ->
    result = @binding
    if result is @ then result
    else getvalue(result)

exports.dummy = (name) -> new exports.DummyVar(name)
exports.dummies = (names) -> new DummyVar(name) for name in split names,  reElements

class exports.Apply
  constructor: (@caller, @args) ->

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

exports.apply = (caller, args) -> new exports.Apply(caller, args)

Command = class exports.Command
  @directRun = false
  @done = (v, solver) -> (solver.done = true; [null, solver.trail.getvalue(v), solver])
  @faildone = (v, solver) -> (solver.done = true; [null, solver.trail.getvalue(v), solver])
  constructor: (@fun, @name) ->
    @callable = (args...) =>
      applied = exports.apply(@, args)
      if Command.directRun
        result = Command.globalSolver.solve(applied, Command.done)
        Command.globalSolver.done = false
        result
      else applied

  register: (exports) -> exports[@name] = @callable
  toString: () -> @name

maker = (klass) -> (name_or_fun, fun) -> (if fun? then new klass(fun, name_or_fun) else new klass(name_or_fun)).callable

class exports.Special extends exports.Command
  apply_cont: (solver, cont, args) -> @fun(solver, cont, args...)

exports.special = special = maker(exports.Special)

class exports.Fun extends exports.Command
  apply_cont: (solver, cont, args) ->  solver.argsCont(args, (params, solver) => [cont, @fun(params...), solver])

exports.fun = maker(exports.Fun)

class exports.Macro extends exports.Command
  apply_cont: (solver, cont, args) -> solver.cont(@fun(args...), cont)

exports.macro = maker(exports.Macro)

class exports.Proc extends exports.Command
  apply_cont:  (solver, cont, args) ->
    (v, solver) =>
      Command.directRun = true
      savedSolver = Command.globalSolver
      Command.globalSolver = solver
      result = @fun(args...)
      Command.globalSolver = savedSolver
      Command.directRun = false
      [cont, result, solver]

exports.proc = maker(exports.Proc)

exports.tofun = (name, cmd) ->
  # cmd can be an instance of subclass of Command, especially macro(macro don't eval its arguments)
  # and specials that don't eval their arguments.
  unless cmd? then (cmd = name; name = 'noname')
  special(name, (solver, cont, args...) ->
          solver.argsCont(args, (params, solver) -> [solver.cont(cmd(params...), cont), params, solver]))