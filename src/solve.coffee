_ = require('underscore')

exports.debug = debug = (items...) ->
  console.log((
      (for x in items
              if (x not instanceof Function)
                s = x.toString()
                if s=='[object Object]' then JSON.stringify(x) else s
              else '[Function]') )...)

Solver = class exports.Solver
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

  cont: (exp, cont = done) -> exp?.cont?(cont) or (-> solver.value = exp; cont())

  quasiquote: (exp, cont) -> exp?.quasiquote?(cont) or (-> solver.value = exp; cont())

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
        -> solver.value = []; cont()
      when 1
        solver.cont(args[0],  -> solver.value = [solver.value];  cont())
      when 2
        solver.cont(args[0], ->
          arg0 = solver.value
          solver.cont(args[1], ->
            arg1 = solver.value
            solver.value = [arg0, arg1]
            cont)())
      when 3
        solver.cont(args[0], ->
          arg0 = solver.value
          solver.cont(args[1], ->
            arg1 = solver.value
            solver.cont(args[2], ->
              solver.value = [arg0, arg1, solver.value];
              cont)())())
      when 4
        solver.cont(args[0], ->
          arg0 = solver.value
          solver.cont(args[1], ->
            arg1 = solver.value
            solver.cont(args[2], ->
              arg2 = solver.value
              solver.cont(args[3], ->
                solver.value = [arg0, arg1, arg2, solver.value]
                cont)())())())
      when 5
        solver.cont(args[0], ->
          arg0 = solver.value
          solver.cont(args[1], ->
            arg1 = solver.value
            solver.cont(args[2], ->
              arg2 = solver.value
              solver.cont(args[3], ->
                arg3 = solver.value
                solver.cont(args[4], ->
                  solver.value = [arg0, arg1, arg2, arg3, solver.value]
                  cont)())())())())
      when 6
        solver.cont(args[0], ->
          arg0 = solver.value
          solver.cont(args[1], ->
            arg1 = solver.value
            solver.cont(args[2], ->
              arg2 = solver.value
              solver.cont(args[3], ->
                arg3 = solver.value
                solver.cont(args[4], ->
                  arg4 = solver.value
                  solver.cont(args[5], ->
                    solver.value = [arg0, arg1, arg2, arg3, arg4, solver.value]
                    cont)())())())())())
      when 7
        solver.cont(args[0], ->
          arg0 = solver.value
          solver.cont(args[1], ->
            arg1 = solver.value
            solver.cont(args[2], ->
              arg2 = solver.value
              solver.cont(args[3], ->
                arg3 = solver.value
                solver.cont(args[4], ->
                  arg4 = solver.value
                  solver.cont(args[5], ->
                    arg5 = solver.value
                    solver.cont(args[6], ->
                      solver.value = [arg0, arg1, arg2, arg3, arg4, arg5, solver.value]
                      cont)())())())())())())
      else
        params = []
        cont = do (cont=cont) ->
          solver.cont(args[length-1], ->
            params.push(solver.value)
            solver.value = params
            cont)
        for i in [args.length-2..0] by -1
          cont = do (i=i, cont=cont) ->
            solver.cont(args[i], ->  (params.push(solver.value); cont()))
        cont

  solve: (exp, cont = done) ->
    cont = @cont(exp, cont or done)
    while not solver.done then cont = cont()
    solver.value

Trail = class exports.Trail
  constructor: (@data={}) ->
  set: (vari, value) ->  if not @data.hasOwnProperty(vari.name) then @data[vari.name] = [vari, value]
  undo: () -> for name, pair of @data then pair[0].binding = pair[1]
  deref: (x) -> x?.deref?(@) or x
  getvalue: (x) -> x?.getvalue?(@) or x
  unify: (x, y) -> x?.unify?(y, @) or y?.unify?(x, @) or (x is y)

exports.done = done = ->
  console.log("succeed!")
  solver.done = true
  solver.failed = false
  solver.value = solver.trail.getvalue(solver.value)
  solver.value

exports.faildone = faildone = ->
  console.log("fail!");
  solver.done = true
  solver.failed = true
  solver.value = solver.trail.getvalue(solver.value)
  solver.value

solver = exports.solver = new exports.Solver(new Trail, faildone)

exports.solve = (exp, trail=new Trail, cont = done, failcont = faildone) ->
  solver.trail= trail
  solver.state = undefined
  solver.failcont = faildone
  solver.done = false
  solver.failed = false
  solver.value = null
  result = solver.solve(exp, cont)
  return result

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

  cont: (cont) -> => (solver.value = @deref(solver.trail); cont())

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

  cont: (cont) -> @caller.apply_cont(cont, @args)

  quasiquote:  (cont) ->
    args = @args
    caller = @caller
    if caller.name is "unquote"
      return  solver.cont(args[0], -> cont())
    else if caller.name is "unquoteSlice"
      return solver.cont(args[0], -> (solver.value = new UnquoteSliceValue(solver.value); cont()))
    length = args.length
    constructor = @constructor
    switch length
      when 0
        do (cont=cont) -> ->  (solver.value = new constructor(caller, []); cont)
      when 1
        do (cont=cont) ->
          solver.quasiquote(args[0], ->
            value = solver.value
            if value instanceof UnquoteSliceValue
              params = value.value
            else params = [value]
            solver.value = new constructor(caller, params)
            cont)
      else
        params = []
        cont = do (cont=cont) -> solver.quasiquote(args[length-1], ->
          value = solver.value
          if value instanceof UnquoteSliceValue
            for x in value.value then params.push x
          else params.push(value);
          solver.value = new constructor(caller, params)
          cont)
        args = @args
        for i in [length-2..0] by -1
          cont = do (i=i, cont=cont) ->
            solver.quasiquote(args[i],  ->
              value = solver.value
              if value instanceof UnquoteSliceValue
                for x in value.value then params.push x
              else params.push(value);
              cont())
        cont

UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

exports.apply = (caller, args) -> new exports.Apply(caller, args)

Command = class exports.Command
  @directRun = false
  constructor: (@fun, @name) ->
    @callable = (args...) =>
      applied = exports.apply(@, args)
      if Command.directRun
        result = solver.solve(applied)
        result
      else applied

  register: (exports) -> exports[@name] = @callable
  toString: () -> @name

maker = (klass) -> (name_or_fun, fun) -> (if fun? then new klass(fun, name_or_fun) else new klass(name_or_fun)).callable

class exports.Special extends exports.Command
  apply_cont: (cont, args) -> @fun(cont, args...)

exports.special = special = maker(exports.Special)

class exports.Fun extends exports.Command
  apply_cont: (cont, args) ->  solver.argsCont(args, () => solver.value = @fun(solver.value...); cont)

exports.fun = maker(exports.Fun)

class exports.Macro extends exports.Command
  apply_cont: (cont, args) -> solver.cont(@fun(args...), cont)

exports.macro = maker(exports.Macro)

class exports.Proc extends exports.Command
  apply_cont:  (cont, args) ->
    fun = @fun
    ->
      Command.directRun = true
      solver.value = fun(args...)
      Command.directRun = false
      cont

exports.proc = maker(exports.Proc)

exports.tofun = (name, cmd) ->
  # cmd can be an instance of subclass of Command, especially macro(macro don't eval its arguments)
  # and specials that don't eval their arguments.
  unless cmd? then (cmd = name; name = 'noname')
  special(name, (cont, args...) ->
          solver.argsCont(args, -> (params = solver.value; solver.cont(cmd(params...), cont))))