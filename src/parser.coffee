_ = require('underscore')

class BacktrackableError

class exports.UnifyError extends BacktrackableError

class VarNotFound
  constructor: (@name) ->

class Env
  constructor: (@outer, bindings) -> @bindings = bindings or {}
  bind: (name, value) ->  @bindings[name] = value
  get: (name) ->
    if @bindings.hasOwnProperty(name) then @bindings[name]
    else if @outer? then return @outer.get name
    else throw new VarNotFound(name)
  add: (name, value) ->
    b = _.clone(@bindings)
    b[name] = value
    new Env(@outer, b)

class Var
  constructor: (@name) ->
  deref: (env) ->
    try
      x = env.get @name
    catch e
      if e instanceof VarNotFound then return @
      else throw e
    if x is @ then x
    else if not (x instanceof Var) then x
    else x.deref env

  unify: (y, env) ->
    y = y.deref env
    env.bind @name y

  toString: ()-> @name+'?'

exports.vars = (names) -> new Var(name) for name in names.split(', ')

unify = (x, y, env) ->
  if x instanceof Var then x = x.deref env
  if y instanceof Var then y = y.deref env
  if x is y then env
  else
    if x instanceof Var then env.add x.name, y
    else if y instanceof Var then env.add y.name, x
    else throw new UnifyError(x, y)

deref = (x, env) ->
  unless x instanceof Var then x
  else x.deref(env)

State = class exports.State
  constructor: (@data, @pos) ->

  toString: -> "#{@data}:#{@pos}"

exports.state = (data, pos) -> new State data, pos

class exports.ParseError extends BacktrackableError
  constructor: (@state, @parser) ->
  toString: -> "ParserError: #{@state.toString()} when parsing #{@parser.toString()}"

class exports.Solver
  constructor: (@env, @state) -> @leftExpr = null
  solve: (exp) -> exp.solve(@)

exports.solve = (exp, data)->
  new Solver(new Env(), new State(data, 0)).solve(exp)

class Expr

class exports.Unify extends Expr
  constructor: (@x, @y) ->

  solve: (solver) ->
    env = unify(@x, @y, solver.env)
    new Solver(env, solver.state)

  toString: ->"#{@x}:=:#{@y}"

exports.unify = (x, y) -> new Unify(x, y)

class exports.Char extends Expr
  constructor: (@arg) ->

  solve: (solver)->
    state  = solver.state
    data = state.data
    pos = state.pos
    if data.length is pos
      throw ParseError(state, @)
    c = data[pos]
    if @arg instanceof Var
      arg = @arg.deref(solver.env)
      if arg instanceof Var
        return new Solver(solver.env.add(arg.name, c), new State(data, pos+1))
    else arg = @arg
    if arg is data[pos]
      new Solver(solver.env, new State(state.data, state.pos+1))
    else throw new ParseError(state, @)

  toString: -> @arg

exports.char = (x) -> new Char x

class exports.And extends Expr
  constructor: (@item1, @item2) ->
  solve: (solver)->
    solver1 = @item1.solve(solver)
    @item2.solve(solver1)
#    @item2.solve(@item1.solve(solver))

  toString: -> "#{item1}&#{@item2}"

exports.and_ = (items...) ->
  len = items.length
  if len is 0 then throw SyntaxError("and_(#{items}")
  if len is 1 then items[0]
  else
    result = items[len-1]
    for i in [len-2..0]
      result = new And items[i], result
    result

class exports.Or extends Expr
  constructor: (@item1, @item2) ->

  solve: (solver)->
    try
      @item1.solve(solver).setLeftExpr(item2)
    catch e
      if e instanceof BacktrackableError then @item2.solve(solver)
      else throw e

  toString: -> "#{item1}|#{@item2}"

exports.or_ = (item1, item2) -> new Or item1, item2

class exports.Not extends Expr
  constructor: (@item) ->

  solve: (solver)->
    try
      @item.solve(solver)
    catch e
      if e instanceof BacktrackableError then return solver
      else throw e
    throw new ParseError(solver.state, @)

  toString: -> "not(#{item})"

exports.not_ = (item) -> new Not item

class exports.Print extends Expr
  constructor: (@items...) ->

  solve: (solver)->
    console.log(x+' ') for x in @items
    solver

  toString: -> "print(#{items})"

exports.print_ = (items) -> new Print items

class exports.Findall extends Expr
  constructor: (@item) ->

  solve: (solver)->
      result = @item.solve(solver)
      other = result.leftExprs
      if other then  new exports.Findal(other).solve(solver)
      else solver

  toString: -> "findall(#{item})"

exports.findall = (item) -> new Findall item
