_ = require("underscore")
il = exports

exports.NotImplement = class NotImplement
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@name} >>> #{@message}"

toString = (o) -> o?.toString?() or o

class Element
  constructor: () ->  @name = @toString()
  isStatement: () -> false
  call: (args...) -> new Apply(@, args)
  toCode: (compiler) -> throw NotImplement(@)
  Object.defineProperty @::, '$', get: -> @constructor

class Var extends Element
  constructor: (@name) ->
  toString: () -> @name
  apply: (args) -> il.apply(@, args)
class Assign extends Element
  constructor: (@vari, @exp) -> super
  toString: () -> "#{toString(@vari)} = #{toString(@exp)}"
class Return extends Element
  constructor: (@value) -> super
  toString: () -> "return(#{toString(@value)})"
class Begin extends Element
  constructor: (@exps) -> super
  toString: () -> "begin(#{(e.toString() for e in @exps).join(',')})"
class Array extends Begin
  toString: () -> "[#{(toString(e) for e in @exps).join(',')}]"
class Print extends Begin
  toString: () -> "print(#{(toString(e) for e in @exps).join(',')})"
class Lamda extends Element
  constructor: (@params, @body) -> super
  toString: () -> "(#{(toString(e) for e in @params).join(', ')} -> #{toString(@body)})"
  call: (args...) -> il.apply(@, args)
  apply: (args) -> il.apply(@, args)
class Clamda extends Element
  constructor: (@v, @body) -> super
  toString: () -> "(#{toString(@v)} -> #{toString(@body)})"
  call: (value) -> il.capply(@, value)
class JSCallable extends Element
  constructor: (@callable) -> super
  toString: () -> "jscallable(#{@callable})"
  apply: (args) -> il.apply(@, args)
class VirtualOperation extends Element
  constructor: (@name) -> super
  toString: () -> "#{@name}"
  call: (args...) -> new VirtualOperationApply(@, args)
  apply: (args) -> new VirtualOperationApply(@, args)
class BinaryOperation extends VirtualOperation
  constructor: (@symbol) -> super
  toString: () -> "binary(#{@symbol})"
  apply: (args) -> new BinaryOperationApply(@, args)
class UnaryOperation extends BinaryOperation
  toString: () -> "unary(#{@symbol})"
  apply: (args) -> new UnaryOperationApply(@, args)
class Fun extends Element
  constructor: (@func) -> super
  toString: () -> "fun(#{@func})"
  apply: (args) -> new Apply(@, args)
class Apply extends Element
  constructor: (@caller, @args) -> super
  toString: () -> "(#{toString(@caller)})(#{(toString(arg) for arg in @args).join(', ')})"
class VirtualOperationApply extends Apply
  toString: () -> "vop(#{toString(@caller)})(#{(toString(arg) for arg in @args).join(', ')})"
class BinaryOperationApply extends Apply
  toString: () -> "#{toString(@args[0])}#{toString(@caller.symbol)}#{toString(@args[1])}"
class VirtualOperationApply extends Apply
  toString: () -> "#{toString(@args[0])}#{toString(@caller.symbol)}#{toString(@args[1])}"
class UnaryOperationApply extends Apply
  toString: () -> "#{toString(@caller.symbol)}#{toString(@args[0])}"
class CApply extends Apply
  constructor: (@cont, @value) -> super
  toString: () -> "#{toString(@cont)}(#{toString(@value)})"
class Deref extends Element
  constructor: (@exp) -> super
  toString: () -> "deref(#{toString(@exp)})"
class Code extends Element
  constructor: (@string) -> super
  toString: () -> "code(#{@string})"
class If extends Element
  constructor: (@test, @then_, @else_) -> super
  toString: () -> "if_(#{toString(@test)}, #{toString(@then_)}, #{toString(@else_)})"

If::isStatement = () -> isStatement(@then_) or isStatement(@else_)
Begin::isStatement = () -> true
Return::isStatement = () -> true
Assign::isStatement = () -> true

jsify = (exp) ->
  exp_jsify = exp?.jsify
  if exp_jsify then exp_jsify.call(exp)
  else exp

insertReturn = (exp) ->
  exp_insertReturn = exp?.insertReturn
  if exp_insertReturn then exp_insertReturn.call(exp)
  else new Return(exp)

isStatement = (exp) ->
  exp_isStatement = exp?.isStatement
  if exp_isStatement then exp_isStatement.call(exp)
  else false

Var::jsify = (compiler) -> @
Assign::jsify = (compiler) -> @
#  vari = @vari
#  [exps, bStatement] = compiler.jsify(@exp)
#  [exps[0...exps.length-1].concat([new Assign(vari, exps[exps.length-1]), vari]), true]
Return::jsify = (compiler) -> throw "Return should not occur before jsify."
If::jsify = (compiler) -> new If(@test, compiler.jsify(@then_), compiler.jsify(@else_))
Begin::jsify = (compiler) ->
  exps = @exps
  length = exps.length
  if length is 0 or length is 1
    throw "begin should have at least one exp"
  result = []
  for e in exps
    result.push(compiler.jsify(e))
  il.begin(result)
Lamda::jsify = (compiler) ->
  body = @body.jsify(compiler)
  body = insertReturn(body)
  new Lamda(@params, body)
Clamda::jsify = (compiler) ->
  body = @body.jsify(compiler)
  body = insertReturn(body)
  new Clamda(@v, body)
Apply::jsify = (compiler) -> new Apply(compiler.jsify(@caller), @args)
CApply::jsify = (compiler) -> new CApply(@cont.jsify(compiler), @value)

Var::optimize = (env, compiler) -> env.lookup(@)
Assign::optimize = (env, compiler) ->  new Assign(compiler.optimize(@vari, env),  compiler.optimize(@exp, env))
If::optimize = (env, compiler) ->
  new If(compiler.optimize(@test, env),  compiler.optimize(@then_, env),  compiler.optimize(@else_, env))
Return::optimize = (env, compiler) -> new Return(compiler.optimize(@value, env))
Clamda::optimize = (env, compiler) -> return new Clamda(@v, compiler.optimize(@body, env))
Apply::optimize = (env, compiler) -> @
CApply::optimize = (env, compiler) -> compiler.optimize(@cont.body, env.extend(@cont.v, compiler.optimize(@value, env)))
Begin::optimize = (env, compiler) ->
  return new @constructor(compiler.optimize(exp, env) for exp in @exps)
Deref::optimize = (env, compiler) ->
  if _.isString(@exp) then exp
  else if _.isNumber(@exp) then exp
  else @
Code::optimize = (env, compiler) -> @
JSCallable::optimize = (env, compiler) -> @

Clamda::toCode = (compiler) ->
    body = (compiler.toCode(exp) for exp in @body).join ';'
    "function(#{compiler.toCode(@v)}){#{compiler.toCode(@body)}}"
Fun::toCode = (compiler) -> @func.toString()
Return::toCode = (compiler) -> "return #{compiler.toCode(@value)};"
Var::toCode = (compiler) -> @name
Assign::toCode = (compiler) -> "#{compiler.toCode(@vari)} = #{compiler.toCode(@exp)}"
If::toCode = (compiler) ->
  "if (#{compiler.toCode(@test)}) #{compiler.toCode(@then_)} else #{compiler.toCode(@else_)};"
Apply::toCode = (compiler) ->
  "(#{compiler.toCode(@caller)})(#{(compiler.toCode(arg) for arg in @args).join(', ')})"
BinaryOperationApply::toCode = (compiler) ->
  "#{compiler.toCode(@args[0])}#{compiler.toCode(@caller.symbol)}#{compiler.toCode(@args[1])}"
UnaryOperationApply::toCode = (compiler) ->
  "#{compiler.toCode(@caller.symbol)}#{compiler.toCode(@args[0])}"
VirtualOperationApply::toCode = (compiler) -> @caller.applyToCode(compiler, @args)
CApply::toCode = (compiler) -> "(#{compiler.toCode(@cont)})(#{compiler.toCode(@value)})"
Begin::toCode = (compiler) -> (compiler.toCode(exp) for exp in @exps).join("; ")
Array::toCode = (compiler) ->  "[#{(compiler.toCode(exp) for exp in @exps).join(', ')}]"
Print::toCode = (compiler) ->  "console.log(#{(compiler.toCode(exp) for exp in @exps).join(', ')})"
Deref::toCode = (compiler) ->  "solver.trail.deref(#{compiler.toCode(@exp)})"
Code::toCode = (compiler) ->  @string
JSCallable::toCode = (compiler) ->  @callable
BinaryOperationApply::toCode = (compiler) ->  "(#{compiler.toCode(@args[0])})#{@caller.symbol}(#{compiler.toCode(@args[1])})"
UnaryOperationApply::toCode = (compiler) ->  "#{@caller.symbol}(#{compiler.toCode(@args[0])})"

il.vari = (name) -> new Var(name)
il.assign = (vari, exp) -> new Assign(vari, exp)
il.if_ = (test, then_, else_) -> new If(test, then_, else_)
il.deref = (exp) -> new Deref(exp)
il.apply = (caller, args) -> new Apply(caller, args)
il.capply = (cont, value) -> new CApply(cont, value)
il.begin = (exps...) ->
  length = exps.length
  if length is 0 then throw "begin should have at least one exp"
  if length is 1 then return exps[0]
  result = []
  for e in exps
    if e instanceof Begin then result.concat(e.exps)
    else result.push result
  new Begin(result)
il.array = (exps...) -> new Array(exps)
il.print = (exps...) -> new Print(exps)
il.return = (value) -> new Return(value)
il.clamda = (v, body...) -> new Clamda(v, il.begin(body...))
il.code = (string) -> new Code(string)
il.jscallable = (callable) -> new JSCallable(callable)
binary = (symbol) -> new BinaryOperation(symbol)
unary = (symbol) -> new UnaryOperation(symbol)
il.eq = binary("===")
il.ne = binary("!==")
il.lt = binary("<")
il.le = binary("<=")
il.gt = binary(">")
il.ge = binary(">=")

il.add = binary("+")
il.sub = binary("-")
il.mul = binary("*")
il.div = binary("/")
il.mod = binary("%")
il.and_ = binary("&&")
il.or_ = binary("||")
il.bitand = binary("&")
il.bitor = binary("|")
il.lshift = binary("<<")
il.rshift = binary(">>")

il.not_ = unary("!")
il.neg = unary("-")
il.bitnot = unary("~")
il.inc = unary("++")
il.dec = unary("--")

vop = (name, toCode) ->
  class Vop extends VirtualOperation
    applyToCode: toCode
  new Vop(name)

il.suffixinc = vop('suffixdec', (compiler, args)->"#{compiler.toCode(args[0])}++")
il.suffixdec = vop('suffixdec', (compiler, args)->"#{compiler.toCode(args[0])}--")
il.protect = vop('protect', (compiler, args)->"solver.protect(#{compiler.toCode(args[0])})")
il.pushCatch = vop('pushCatch', (compiler, args)->"solver.pushCatch(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")
il.popCatch = vop('popCatch', (compiler, args)->"solver.popCatch(#{compiler.toCode(args[0])})")
il.findCatch = vop('findCatch', (compiler, args)->"solver.findCatch(#{compiler.toCode(args[0])})")
il.fake = vop('fake', (compiler, args)->"solver.fake(#{compiler.toCode(args[0])})").apply([])
il.restore = vop('restore', (compiler, args)->"solver.restore(#{compiler.toCode(args[0])})")
il.getvalue = vop('getvalue', (compiler, args)->"solver.trail.getvalue(#{compiler.toCode(args[0])})")
il.index = vop('index', (compiler, args)->"(#{compiler.toCode(args[0])})[#{compiler.toCode(args[1])}]")
il.run = vop('run', (compiler, args)->"solver.run(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")
il.failcont = vop('failcont', (compiler, args)->"solver.failcont(#{compiler.toCode(args[0])})")

il.fun = (f) -> new Fun(f)