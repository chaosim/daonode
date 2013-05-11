_ = require('underscore')

dao = exports

class dao.Env
  constructor: (@bindings = {}, @outer) ->
  extend:(bindings) -> new Environemt(bindings, @)
  get: (vari) ->
    env = @
    while env
      if @bindings.hasOwnProperty(vari.name)
        return @bindings[vari.name]
      env = env.outer
    return vari
  set: (vari, value) -> @bindings[vari.name] = value; @

class dao.Bindings
  constructor: (@map = {}) ->
  clone: () -> new dao.Bindings(_.extend({}, @map))
  get:(vari) -> if @map.hasOwnProperty(vari.name) then @map[vari.name] else vari
  set: (vari, value) -> @map[vari.name] = value; @

deref = (x, env) -> if x instanceof dao.Var then x.deref(env) else x

done =(v, solver) ->
  console.log("succeed!");
  result = v.getvalue(solver.env)
  if result instanceof dao.Atom then result.item
  else result

faildone =(v, solver) ->
  console.log("fail!");
  result = v.getvalue(solver.env)
  if result instanceof dao.Atom then result.item
  else result

dao.solve = (exp, env = new dao.Bindings(), cont = done, failcont = faildone) ->
  if _.isNumber(exp) then exp = dao.number(exp)
  else if _.isString(exp) then exp = dao.string(exp)
  else if  not _.isObject(exp)  then exp = dao.atom(exp)
  else if not exp instanceof dao.Element then exp = dao.atom(exp)
  new dao.Solver(env, failcont).solve(exp)

class dao.Solver
  constructor: (@env, @failcont, @state) ->
  clone: (update={}) -> new dao.Solver(update.env or @env.clone(), update.failcont or @failcont, update.state or @state)
  cont: (exp, cont) -> exp.cont(@, cont or done)
  solve: (exp, cont) -> cont = @cont(exp, cont or done); cont(dao.NULL, @)

class dao.Element
class dao.Var extends dao.Element
  constructor: (@name) ->
class dao.Atom extends dao.Element
  constructor: (@item) ->
class dao.Number extends dao.Atom
class dao.Print extends dao.Element
  constructor: (@args...) ->
class dao.Succeed extends dao.Element
class dao.Fail extends dao.Element
class dao.And extends dao.Element
  constructor: (@x, @y) ->
class dao.Or extends dao.Element
  constructor: (@x, @y) ->
class dao.Not extends dao.Element
  constructor: (@x) ->
class dao.Unify extends dao.Element
  constructor: (@x, @y) ->
class dao.Parse extends dao.Element
  constructor: (@exp, @data) ->
class dao.Char extends dao.Element
  constructor: (@x) ->

dao.vari = (name) -> new dao.Var(name)
dao.atom = (x) -> new dao.Atom(x)
dao.number = (x) -> new dao.Number(x)
dao.print_ = (x...) -> new dao.Print(x...)
dao.succeed = new dao.Succeed()
dao.fail = new dao.Fail()
dao.and_ = (x, y) -> new dao.And(x, y)
dao.or_ = (x, y) -> new dao.Or(x, y)
dao.not_ = (x, y) -> new dao.Not(x)
dao.unify = (x, y) -> new dao.Unify(x, y)
dao.parse = (exp, data) -> new dao.Parse(exp, data)
dao.char = (x) -> new dao.Char(x)

dao.Var::toString = "dao.vari(#{@name})"
dao.Atom::toString = "dao.atom(#{@item})"
dao.Number::toString = "dao.number(#{@item})"
dao.Succeed::toString = "dao.succeed"
dao.Number::toString = "dao.fail"
dao.TRUE = dao.atom(true)
dao.FALSE = dao.atom(false)
dao.NULL = dao.atom(null)
dao.And::toString = "dao.and_(#{@x}, #{@y})"
dao.Or::toString = "dao.or_(#{@x}, #{@y})"
dao.Not::toString = "dao.not_(#{@x})"
dao.Unify::toString = "dao.unify_(#{@x}, #{@y})"
dao.Parse::toString = "dao.parse(#{@exp}, #{@data})"
dao.Char::toString = "dao.char(#{@x})"

dao.Element::deref = (env) -> @
dao.Var::deref = (env) -> env.get(@)

dao.Element::getvalue = (env) -> @
dao.Var::getvalue = (env) ->@deref(env)

dao.Var::cont = (solver, cont) -> (v, solver) => cont(@.deref(solver.env), solver)
dao.Atom::cont = (solver, cont) -> (v, solver) => cont(@, solver)
dao.Print::cont = (solver, cont) -> (v, solver) => console.log(@args...); cont(dao.NULL, solver)
dao.Succeed::cont = (solver, cont) -> (v, solver) -> cont(dao.FALSE, solver)
dao.Fail::cont = (solver, cont) -> (v, solver) -> solver.failcont(dao.FALSE, solver)

dao.And::cont = (solver, cont) -> @x.cont(solver, @y.cont(solver, cont))

dao.Or::cont = (solver, cont) ->
  fc = solver.failcont
  saved_solver = solver.clone()
  solver.failcont = (v, solver) => @y.cont(solver, cont)(v, saved_solver)
  @x.cont(solver, ((v, solver) -> solver.failcont = fc; cont(v, solver)))

dao.Not::cont = (solver, cont) ->
  fc = solver.failcont
  saved_solver = solver.clone()
  solver.failcont = cont
  @x.cont(solver, (v, solver)->fc(v, saved_solver))

dao.Unify::cont = (solver, cont) -> (v, solver) =>
    x = deref(@x, solver.env)
    y = deref(@y, solver.env)
    if x instanceof dao.Var
      solver.env.set(x, y)
      cont(dao.TRUE, solver)
    else if y instanceof dao.Var
      solver.env.set(y, x)
      cont(dao.TRUE, solver)
    else if x is y then cont(dao.TRUE, solver)
    else solver.failcont(dao.FALSE, solver)

dao.Parse::cont = (solver, cont) -> (v, solver) =>
  state = solver.state
  solver.state = [@data, 0]
  @.exp.cont(solver, ((v, solver) -> solver.state = state; cont(v, solver)))(dao.TRUE, solver)

dao.Char::cont = (solver, cont) -> (v, solver) =>
  [data, pos] = solver.state
  if pos is data.length then return solver.failcont(dao.FALSE, solver)
  x = deref(@x, solver.env)
  c = data[pos]
  if _.isString(x)
    if x is c then solver.state = [data, pos+1]; cont(dao.TRUE, solver)
    else solver.failcont(v, solver)
  else if x instanceof dao.Var
    solver.env.set(x, c)
    cont(dao.TRUE, solver)
  else throw new dao.TypeError(@)
