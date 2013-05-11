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
  add: (vari, value) -> new dao.Bindings(_.extend({}, @map)).set(vari, value)
  get:(vari) -> if @map.hasOwnProperty(vari.name) then @map[vari.name] else vari
  set: (vari, value) -> @map[vari.name] = value; @

deref = (x, env) -> if x instanceof dao.Var then x.deref(env) else x

done =(fc) -> (v, solver) ->
  console.log("succeed!");
  result = v.getvalue(solver.env)
  if result instanceof dao.Atom then result.item
  else result

faildone = (fc) -> (v, solver) -> console.log("fail!"); false;

dao.solve = (exp, env = new dao.Bindings(), cont = done, fcont = done) ->
  if _.isNumber(exp) then exp = dao.number(exp)
  else if _.isString(exp) then exp = dao.string(exp)
  else if  not _.isObject(exp)  then exp = dao.atom(exp)
  else if not exp instanceof dao.Element then exp = dao.atom(exp)
  new dao.Solver(env, cont).solve(exp)

class dao.Solver
  constructor: (@env, @state) ->
  clone: (update={}) -> new dao.Solver(update.env or @env, update.state or @state)
  cont: (exp, cont) -> exp.cont(@, cont or done)
  solve: (exp, cont, fcont) -> cont = @cont(exp, cont or done); cont(fcont or faildone)(dao.NULL, @)

class dao.Element
class dao.Var extends dao.Element
  constructor: (@name) ->
class dao.Atom extends dao.Element
  constructor: (@item) ->
class dao.Number extends dao.Atom
  getvalue: (env) -> @item
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

dao.Element::deref = (env) -> @
dao.Var::deref = (env) -> env.get(@)

dao.Element::getvalue = (env) -> @
dao.Var::getvalue = (env) ->@deref(env)

dao.Var::cont = (solver, cont) -> (fc) => (v, solver) => cont(fc)(@.deref(solver.env), solver)
dao.Atom::cont = (solver, cont) -> (fc) => (v, solver) => cont(fc)(@, solver)
dao.Print::cont = (solver, cont) -> (fc) => (v, solver) => console.log(@args...); cont(fc)(dao.NULL, solver)
dao.Succeed::cont = (solver, cont) -> (fc) => (v, solver) => cont(fc)(dao.TRUE, solver)
dao.Fail::cont = (solver, cont) -> (fc) => (v, solver) => fc(faildone)(dao.FALSE, solver)
dao.And::cont = (solver, cont) ->
  y_cont = @y.cont(solver, cont)
  and_cont = (fc) => (v, solver) => y_cont(fc)(v, solver)
  x_cont = @x.cont(solver, and_cont)
  (fc) => (v, solver) => x_cont(fc)(v, solver)
dao.Or::cont = (solver, cont) ->
  x_cont = @x.cont(solver, cont)
  y_cont = @y.cont(solver, cont)
  (fc) =>  (v, solver) => x_cont(y_cont)(v, solver)
dao.Not::cont = (solver, cont) -> (fc) =>  @x.cont(solver, fc)(cont)
dao.Unify::cont = (solver, cont) -> (fc) =>  (v, solver) =>
    x = deref(@x, solver.env)
    y = deref(@y, solver.env)
    if x instanceof dao.Var then cont(dao.TRUE, solver.clone(env:solver.env.add(x, y)))
    else if y instanceof dao.Var then cont(dao.TRUE, solver.clone(env:solver.env.add(y, x)))
    else if x is y then cont(dao.TRUE, solver)
    else fc(false, dao.FALSE)

