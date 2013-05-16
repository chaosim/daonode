_ = require('underscore')

exports.debug = debug = (items...) ->
  console.log((
      (for x in items
              if (x not instanceof Function)
                s = x.toString()
                if s=='[object Object]' then JSON.stringify(x) else s
              else '[Function]') )...)

done =(v, solver) -> console.log("succeed!"); solver.done = true; [null, solver.trail.getvalue(v), solver]

faildone =(v, solver) -> console.log("fail!"); solver.done = true;  [null, solver.trail.getvalue(v), solver]

exports.solve = (exp, trail=new exports.Trail, cont = done, failcont = faildone) ->
  new exports.Solver(trail, failcont).solve(exp)

exports.solver = (trail = {}, failcont = faildone, state) -> new exports.Solver(trail, failcont, state)

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

  protect: (fun) -> (v, solver) -> [fun, v, solver]

  cont: (exp, cont = done) -> exp?.cont?(@, cont) or ((v, solver) -> cont(exp, solver))

  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else @cont(exps[0], @expsCont(exps[1...], cont))

  solve: (exp, cont = done) ->
    cont = @cont(exp, cont or done)
    value = null
    solver = @
    while not solver.done
      [cont, value, solver] = cont(value, solver)
    value

class exports.Trail
  constructor: (@data={}) ->
  set: (vari, value) ->  if not @data.hasOwnProperty(vari.name) then @data[vari.name] = [vari, value]
  undo: () -> for name, pair of @data then pair[0].binding = pair[1]
  deref: (x) -> x?.deref?(@) or x
  getvalue: (x) -> x?.getvalue?(@) or x
  unify: (x, y) -> x?.unify?(y, @) or y?.unify?(x, @) or (x is y)

class exports.Var
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

exports.vari = (name) -> new exports.Var(name)

class exports.Apply
  constructor: (@caller, @args) ->

  toString: -> "#{@caller}(#{@args.join(', ')})"
  cont: (solver, cont) -> @caller.apply_cont(solver, cont, @args)

exports.apply = (caller, args) -> new exports.Apply(caller, args)

Command = class exports.Command
  @directRun = false
  @done = (v, solver) -> (solver.done = true; [null, solver.trail.getvalue(v), solver])
  @faildone = (v, solver) -> (solver.done = true; [null, solver.trail.getvalue(v), solver])
  constructor: (@fun, @name) ->
#    debug 'enter command constructor a321455665'
    @callable = (args...) =>
      if @name is 'a' then debug 'enter command callable'
      applied = exports.apply(@, args)
      if Command.directRun
        fc = solver.failcont
        folver.failcont = command.faildone
        [cont, reuslt, solver] = Command.globalSolver.solve(applied, done)
        solver.failcont = fc
        solver.done = false
      else applied

  register: (exports) -> exports[@name] = @callable
  toString: () -> @name

maker = (klass) -> (name_or_fun, fun) -> (if fun? then new klass(fun, name_or_fun) else new klass(name_or_fun)).callable

class exports.Special extends exports.Command
  apply_cont: (solver, cont, args) -> @fun(solver, cont, args...)

exports.special = maker(exports.Special)

class exports.Fun extends exports.Command
  apply_cont: (solver, cont, args) ->
    length = args.length
    params = (i for i in [0...length])
    cont = do (cont=cont) => (caller, solver) => cont(@fun(params...), solver)
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        solver.cont(args[i], (v, solver) ->  (params[i] = v; cont(null, solver)))
    cont

exports.fun = maker(exports.Fun)

class exports.Macro extends exports.Command
  apply_cont: (solver, cont, args) -> solver.cont(@fun(args...), cont)

exports.macro = maker(exports.Macro)

class exports.Rule extends exports.Command
  apply_cont:  (solver, cont, args) =>
    debug 'enter rule apply_con'
    throw 'dasffa'
    (v, solver) ->
      debug 'enter rule apply_cont run'
      savedSolver = Command.globalSolver
      Command.globalSolver = solver
      throw 'dasffa'
      result = @fun(args...)
      Command.globalSolver = savedSolver
      throw 'dasffa'
      [cont, result, solver]

exports.rule = maker(exports.Rule)