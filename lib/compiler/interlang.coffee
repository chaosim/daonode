il = exports

class Atom
  constructor: (@value) ->
class Number extends Atom
class Var
  constructor: (@name) ->
class Apply
  constructor: (@caller, @args) ->
class Return
  constructor: (@value) ->
class Begin
  constructor: (@exps) ->
class Array extends Begin
class Clamda
  constructor: (@v, @body) ->
  call: (value) -> il.apply(@, value)

Var::optimize = (env, compiler) -> env.lookup(@)
Return::optimize = (env, compiler) ->
  value = @value
  if value instanceof Array
    value = value.exps
    if value.length is 2
      value0 = value[0]
      if value0 instanceof Clamda
        body = compiler.optimize(value0.body, env.extend(value0.v, value[1]))
        if body instanceof Return then body = body.value
        return new Return(body)
  new Return(compiler.optimize(@value, env))

Clamda::optimize = (env, compiler) -> return new Clamda(@v, compiler.optimize(@body, env))
Apply::optimize = (env, compiler) ->
  caller = @caller
  if caller instanceof Clamda
    compiler.optimize(caller.body, env.extend(caller.v, @args[0]))
  else @
Begin::optimize = (env, compiler) ->
  return new @constructor(compiler.optimize(exp, env) for exp in @exps)

Clamda::toCode = (compiler) ->
    body = (compiler.toCode(exp) for exp in @body).join ';'
    "function(#{compiler.toCode(@v)}){#{compiler.toCode(@body)}}"
Return::toCode = (compiler) -> "return #{compiler.toCode(@value)};"
Var::toCode = (compiler) -> @name
Apply::toCode = (compiler) -> "(#{compiler.toCode(@caller)})(#{(compiler.toCode(arg) for arg in @args).join(', ')})"
Begin::toCode = (compiler) -> (compiler.toCode(exp) for exp in @exps).join("; ")
Array::toCode = (compiler) ->  "[#{(compiler.toCode(exp) for exp in @exps).join(', ')}]"


il.vari = (name) -> new Var(name)
il.apply = (caller, args) -> new Apply(caller, args)
il.begin = (exps...) ->
  length = exps.length
  if length is 0 then il.undefined
  else if length is 1 then exps[0]
  else new Begin(exps)
il.array = (exps...) -> new Array(exps)
il.return = (value) -> new Return(value)
il.clamda = (v, body...) -> new Clamda(v, il.begin(body...))
