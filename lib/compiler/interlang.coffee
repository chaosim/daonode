_ = require("underscore")
{Env, solve} = core = require("./core")

il = exports

exports.NotImplement = class NotImplement extends Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@name} >>> #{@exp} #{@message}"

toString = (o) -> o?.toString?() or o

class Element
  constructor: () ->  @name = @toString()
  call: (args...) -> new Apply(@, args)
  apply: (args) -> new Apply(@, args)
  toCode: (compiler) -> throw new  NotImplement(@, "toCode")
  Object.defineProperty @::, '$', get: -> @constructor

class Var extends Element
  constructor: (@name) ->
  toString: () -> @name
class Symbol extends Var
class Assign extends Element
  constructor: (@left, @exp) -> super
  toString: () -> "#{toString(@left)} = #{toString(@exp)}"
class ListAssign extends Assign
  constructor: (@lefts, @exp) -> @name = @toString()
  toString: () -> "#{toString(@lefts)} = #{toString(@exp)}"
class AugmentAssign extends Assign
  toString: () -> "#{toString(@left)} #{@constructor.operator}= #{toString(@exp)}"
class Return extends Element
  constructor: (@value) -> super
  toString: () -> "return(#{toString(@value)})"
class Throw extends Return
  toString: () -> "throw(#{toString(@value)})"
class Begin extends Element
  constructor: (@exps) -> super
  toString: () -> "begin(#{(toString(e) for e in @exps).join(',')})"
class Print extends Begin
  toString: () -> "print(#{(toString(e) for e in @exps).join(',')})"
class Lamda extends Element
  constructor: (@params, @body) -> super
  toString: () -> "(#{(toString(e) for e in @params).join(', ')} -> #{toString(@body)})"
  call: (args...) -> new Apply(@, args)
  apply: (args) -> new Apply(@, args)
class Clamda extends Lamda
  constructor: (@v, @body) -> @name = @toString()
  toString: () -> "(#{toString(@v)} -> #{toString(@body)})"
  call: (value) -> new CApply(@, value)
class ClamdaBody extends Clamda
  toString: () -> "{#{@v}: #{toString(@body)}}"
  call: (value) -> new Error("How is it happened to call with ClamdaBody? #{@}")
class IdCont extends Clamda
class JSFun extends Element
  constructor: (@fun) -> super
  toString: () -> "jsfun(#{@fun})"
  apply: (args) -> new Apply(@, args)
exports.VirtualOperation = class VirtualOperation extends Element
  constructor: (@args) -> super
  toString: () -> "vop_#{@_name}(#{(toString(arg) for arg in @args).join(', ')})"
class BinaryOperation extends VirtualOperation
  toString: () -> "#{toString(@args[0])}#{@symbol}#{toString(@args[1])}"
  _effect: false
class UnaryOperation extends BinaryOperation
  toString: () -> "#{@symbol}#{toString(@args[0])}"
  _effect: false
class Fun extends Element
  constructor: (@func) -> super
  toString: () -> "fun(#{@func})"
  apply: (args) -> new Apply(@, args)
class Apply extends Element
  constructor: (@caller, @args) -> super
  toString: () -> "(#{toString(@caller)})(#{(toString(arg) for arg in @args).join(', ')})"
class CApply extends Apply
  constructor: (cont, value) -> @caller = cont; @args = [value]; @name = @toString()
class Deref extends Element
  constructor: (@exp) -> super
  toString: () -> "deref(#{toString(@exp)})"
class Code extends Element
  constructor: (@string) -> super
  toString: () -> "code(#{@string})"
class If extends Element
  constructor: (@test, @then_, @else_) -> super
  toString: () -> "if_(#{toString(@test)}, #{toString(@then_)}, #{toString(@else_)})"

optimize = (exp, env, compiler) ->
  exp_optimize = exp?.optimize
  if exp_optimize then exp_optimize.call(exp, env, compiler)
  else exp

Var::optimize = (env, compiler) -> env.lookup(@)
Assign::optimize = (env, compiler) ->
  left = @left
  if left instanceof VirtualOperation
    left = new left.constructor(compiler.optimize(a, env) for a in left.args)
  new @constructor(left, compiler.optimize(@exp, env))
ListAssign::optimize = (env, compiler) ->
  lefts = []
  for left in @lefts
    if left instanceof VirtualOperation
      lefts.push new left.constructor(compiler.optimize(a, env) for a in left.args)
    else lefts.push left
  new @constructor(lefts, compiler.optimize(@exp, env))
If::optimize = (env, compiler) ->
  test = optimize(@test, env, compiler)
  test_bool = boolize(test)
  if test_bool is true
    then_ = optimize(@then_, env, compiler)
    if then_ instanceof If and then_.test is test # (if a (if a b c) d)
      then_ = then_.then_
    then_
  else if test_bool is false
    else_ = optimize(@else_, env, compiler)
    if else_ instanceof If and else_.test is test # (if a b (if a c d))
      else_ = else_.else_
    else_
  else
    then_= optimize(@then_, env, compiler)
    else_ = optimize(@else_, env, compiler)
    if then_ instanceof If and then_.test is test # (if a (if a b c) d)
      then_ = then_.then_
    if else_ instanceof If and else_.test is test # (if a b (if a c d))
      else_ = else_.else_
    new If(test, then_, else_)

Return::optimize = (env, compiler) -> new Return(compiler.optimize(@value, env))
Throw::optimize = (env, compiler) -> new Throw(compiler.optimize(@value, env))
Lamda::optimize = (env, compiler) ->
  result = new Lamda(@params, compiler.optimize(@body, env))
  result.refMap = {}
  result.analyze(compiler,  result.refMap)
  return result
Clamda::optimize = (env, compiler) ->
  result = new Clamda(@v, compiler.optimize(@body, env.extend(@v, @v)))
  result.refMap = {}
  result.analyze(compiler,  result.refMap)
  return result
ClamdaBody::optimize = (env, compiler) ->new ClamdaBody(@v, compiler.optimize(@body, env.extend(@v, @v)))
IdCont::optimize = (env, compiler) -> @

Apply::optimize = (env, compiler) ->
  caller =  compiler.optimize(@caller, env)
  args = (compiler.optimize(a, env) for a in @args)
  caller.optimizeApply?(args, env, compiler) or new Apply(caller, args)

VirtualOperation::optimize = (env, compiler) ->
  args = (compiler.optimize(a, env) for a in @args)
  myBoolize = (memo, x) ->
    if memo is undefined then undefined
    else if boolize(x) is undefined then undefined
    else true
  bool = _.reduce(args, myBoolize, true)
  if bool and @func then @func.apply(null, args)
  else new @constructor(args)

Begin::optimize = (env, compiler) ->
  result = []
  for exp in @exps
    e = compiler.optimize(exp, env)
    if e instanceof Begin then result = result.concat(e.exps)
    else result.push e
  return new Begin(result)
Deref::optimize = (env, compiler) ->
  exp = @exp
  if _.isString(exp) then exp
  else if _.isNumber(exp) then exp
  else new Deref(compiler.optimize(exp, env))
Code::optimize = (env, compiler) -> @
JSFun::optimize = (env, compiler) ->  new JSFun(compiler.optimize(@fun, env))

Var::optimizeApply = (args, env, compiler) ->  new Apply(@, args)
Apply::optimizeApply = (args, env, compiler) ->  new Apply(@, args)

Lamda::optimizeApply = (args, env, compiler) ->
    params = @params
    body = @body
    paramsLength = params.length
    if paramsLength is 0 then return compiler.optimize(body, env)
    newParams = []; newArgs = []; bindings = {}
    refMap = @refMap
    for p, i in params
      arg = args[i]
      if sideEffect(arg)
        newParams.push(p)
        newArgs.push(arg)
        continue
      else
        refCount = refMap[p]
        switch refCount
          when 1 then bindings[p] = arg
          else
            if codeSize(arg)*refCount>MAX_EXTEND_CODE_SIZE
              newParams.push(p)
              newArgs.push(arg)
            else bindings[p] = arg
    if newParams.length isnt 0
      if not isEmpty(bindings) then env = env.extendBindings(bindings)
      new Apply(new Lamda(newParams, compiler.optimize(body, env)), newArgs)
    else
      if bindings then compiler.optimize(body, env.extendBindings(bindings))
      else  compiler.optimize(body, env)

Clamda::optimizeApply = (args, env, compiler) ->
  cont = @; body = cont.body; v = cont.v; value = compiler.optimize(args[0], env)
  count = cont.refMap[v]
  if sideEffect(value)
    switch count
      when 0, undefined then il.begin(value, compiler.optimize(body, env))
      else il.begin(il.assign(v, value), il.clamdabody(v, compiler.optimize(body, env.extend(v, v))))
  else compiler.optimize(body, env.extend(v, value))

IdCont::optimizeApply = (args, env, compiler) -> compiler.optimize(args[0], env)

JSFun::optimizeApply = (args, env, compiler) ->
    cont = args[0]
    f = @fun
    t = typeof f
    if t is 'function' then cont.call(new Apply(f, args[1...]))
    else if t is 'string' then cont.call(new Apply(il.fun(f), args[1...]))
    else cont.call(f.apply(args[1...])).optimize(env, compiler)

MAX_EXTEND_CODE_SIZE = 10

hasOwnProperty = Object::hasOwnProperty
isEmpty = (obj) ->
  for key of obj  then if hasOwnProperty.call(obj, key) then return false
  return true

analyze = (exp, compiler, refMap) ->
  exp_analyze = exp?.analyze
  if exp_analyze then exp_analyze.call(exp, compiler, refMap)

Var::analyze = (compiler, refMap) -> if hasOwnProperty.call(refMap, @) then refMap[@]++ else refMap[@] = 1
Assign::analyze = (compiler, refMap) -> analyze(@exp, compiler, refMap)
If::analyze = (compiler, refMap) ->
  analyze(@test, compiler, refMap) + analyze(@then_, compiler, refMap) + analyze(@else_, compiler, refMap)
Begin::analyze = (compiler, refMap) -> analyze(e, compiler, refMap) for e in @exps
Return::analyze = (compiler, refMap) -> analyze(@value, compiler, refMap)
Apply::analyze = (compiler, refMap) ->
  analyze(@caller, compiler, refMap); analyze(e, compiler, refMap) for e in @args
VirtualOperation::analyze = (compiler, refMap) -> analyze(e, compiler, refMap) for e in @args
CApply::analyze = (compiler, refMap) ->  analyze(@cont, compiler, refMap); analyze(@value, compiler, refMap)
Lamda::analyze = (compiler, refMap) ->
  childMap = @refMap = {}
  analyze(@body, compiler, childMap)
  for x, i of childMap
    if x not in @params
      if hasOwnProperty.call(refMap, x) then refMap[x] += i else refMap[x] = i
Clamda::analyze = (compiler, refMap) ->
  childMap = @refMap = {}
  analyze(@body, compiler, childMap)
  for x, i of childMap
    if x!=@v.name
      if hasOwnProperty.call(refMap, x) then refMap[x] += i else refMap[x] = i
ClamdaBody::analyze = (compiler, refMap) ->
  childMap = @refMap = {}
  analyze(@body, compiler, childMap)
  for x, i of childMap
    if x!=@v.name
      if hasOwnProperty.call(refMap, x) then refMap[x] += i else refMap[x] = i

codeSize = (exp) ->
  exp_codeSize = exp?.codeSize
  if exp_codeSize then exp_codeSize.call(exp)
  else 1

Var::codeSize = () -> 1
Return::codeSize = () -> codeSize(@value)+1
If::codeSize = () -> sideEffeft(@test) + codeSize(@then_) + codeSize(@else_) + 1
Begin::codeSize = () -> _.reduce(@exps, ((memo, e) -> memo + codeSize(e)), 0)
VirtualOperation::codeSize = () -> 1
Lamda::codeSize = () -> codeSize(@body) + 2
Clamda::codeSize = () -> codeSize(@body) + 1
ClamdaBody::codeSize = () -> codeSize(@body)
Apply::codeSize = () -> _.reduce(@args, ((memo, e) -> memo + codeSize(e)), codeSize(@caller))
CApply::codeSize = () -> codeSize(@caller.body) + codeSize(@args[0]) + 2

boolize = (exp) ->
  exp_boolize = exp?.boolize
  if exp_boolize then exp_boolize.call(exp)
  else !!exp

Var::boolize = () -> undefined
Return::boolize = () -> boolize(@value)
If::boolize = () ->
  b = boolize(@test)
  if b is undefined then undefined
  if b is true then boolize(@then_) else boolize(@else_)
Begin::boolize = () -> exps = @exps; boolize(exps[exps.length-1])
VirtualOperation::boolize = () ->
  for a in @args then if boolize(a) is undefined then return undefined
  !!(@func?.apply(null, @args)) or undefined
Lamda::boolize = () -> true
Clamda::boolize = () -> true
ClamdaBody::boolize = () -> boolize(@body)
Apply::boolize = () ->
  caller = @caller
  if caller instanceof Lamda or caller instanceof Clamda then return boolize(caller.body)
  if caller instanceof Var then return undefined
  for a in @args then if boolize(a) is undefined then return undefined
  !!(caller.func?.apply(null, @args)) or undefined
CApply::boolize = () -> boolize(@caller.body)

il.PURE = 0; il.EFFECT = 1; il.IO = 2
il.pure = pure = (exp) -> exp._effect = il.PURE; exp
il.effect = (exp) -> exp._effect = il.EFFECT; exp
il.io = (exp) -> exp._effect = il.IO; exp

sideEffect = (exp) ->
  exp_effect = exp?.sideEffect
  if exp_effect then exp_effect.call(exp)
  else il.PURE

expsEffect = (exps) ->
  effect = il.PURE
  for e in exps
    eff = sideEffect(e)
    if eff == il.IO then return il.IO
    if eff == il.EFFECT then effect = eff
  effect

Var::sideEffect = () -> il.EFFECT
Return::sideEffect = () -> sideEffect(@value)
If::sideEffect = () -> expsEffect [@test, @then_, @else_]
Begin::sideEffect = () -> expsEffect(@exps)
Apply::sideEffect = () ->  Math.max(applySideEffect(@caller), expsEffect(@args))
VirtualOperation::sideEffect = () ->  Math.max(@_effect, expsEffect(@args))
CApply::sideEffect = () -> Math.max(applySideEffect(@caller), sideEffect(@args[0]))

applySideEffect = (exp) ->
  exp_applySideEffect = exp?.applySideEffect
  if exp_applySideEffect then exp_applySideEffect.call(exp)
  else  throw new Error(exp)

Element::applySideEffect = () -> throw new NotImplement(@, 'applySideEffect')
Var::applySideEffect = () -> il.IO
Apply::applySideEffect = () -> il.IO
VirtualOperation::applySideEffect = () -> il.IO
Fun::applySideEffect = () -> if @_effect? then  @_effect else il.IO
JSFun::applySideEffect = () -> if @_effect? then  @_effect else il.IO
Lamda::applySideEffect = () -> if @_effect? then  @_effect else sideEffect(@body)
Clamda::applySideEffect = () -> if @_effect? then  @_effect else sideEffect(@body)

IO = (exp) ->
  exp_IO = exp?.IO
  if exp_IO then exp_IO.call(exp)
  else false

jsify = (exp) ->
  exp_jsify = exp?.jsify
  if exp_jsify then exp_jsify.call(exp)
  else exp

Assign::jsify = () -> new @constructor(@left, jsify(@exp))
ListAssign::jsify = () ->
  lefts = @lefts; exp =  @exp
  il.begin((new Assign(lefts[i], il.index(exp, i)) for i in [0...lefts.length])...)

If::jsify = () -> new If(@test, jsify(@then_), jsify(@else_))
Begin::jsify = () ->
  exps = @exps
  length = exps.length
  if length is 0 or length is 1
    throw new  Error "begin should have at least one exp"
  result = []
  for e in exps
    result.push(jsify(e))
  new Begin(result)
Lamda::jsify = () ->
  body = jsify(@body)
  body = insertReturn(body)
  new Lamda(@params, body)
Clamda::jsify = () ->
  body = jsify(@body)
  body = insertReturn(body)
  new Clamda(@v, body)
ClamdaBody::jsify = () -> jsify(@body)
Apply::jsify = () ->
  args = (jsify(a) for a in @args)
  new @constructor(jsify(@caller), args)
CApply::jsify = () -> new CApply(@caller.jsify(), jsify(@args[0]))
VirtualOperation::jsify = () ->
  args = (jsify(a) for a in @args)
  new @constructor(args)

insertReturn = (exp) ->
  exp_insertReturn = exp?.insertReturn
  if exp_insertReturn then exp_insertReturn.call(exp)
  else new Return(exp)

Assign::insertReturn = () -> il.begin(@, il.return(@left))
Return::insertReturn = () -> @
If::insertReturn = () ->
  if @isStatement() then new If(@test, insertReturn(@then_), insertReturn(@else_))
  else new Return(@)
Begin::insertReturn = () ->
  exps = @exps
  length = exps.length
  exps[length-1] = insertReturn(exps[length-1])
  il.begin(exps...)

Lamda::toCode = (compiler) ->
  compiler.parent = @
  "function(#{(a.name for a in @params).join(', ')}){#{compiler.toCode(@body)}}"
Clamda::toCode = (compiler) ->
  compiler.parent = @
  "function(#{@v.name}){#{compiler.toCode(@body)}}"
Fun::toCode = (compiler) -> @func.toString()
Return::toCode = (compiler) -> "return #{compiler.toCode(@value)};"
Throw::toCode = (compiler) -> "throw #{compiler.toCode(@value)};"
Var::toCode = (compiler) -> @name
Assign::toCode = (compiler) -> "#{compiler.toCode(@left)} = #{compiler.toCode(@exp)}"
AugmentAssign::toCode = (compiler) -> "#{compiler.toCode(@left)} #{@operator} #{compiler.toCode(@exp)}"
If::toCode = (compiler) ->
  compiler.parent = @
  else_ = @else_
  if @isStatement()
    if else_ is undefined then "if (#{compiler.toCode(@test)}) #{compiler.toCode(@then_)}"
    else "if (#{compiler.toCode(@test)}) #{compiler.toCode(@then_)} else #{compiler.toCode(@else_)}"
  else
    "(#{compiler.toCode(@test)}) ? (#{compiler.toCode(@then_)}) : (#{compiler.toCode(@else_)})"
#    if else_ is undefined then "((#{compiler.toCode(@test)}) && (#{compiler.toCode(@then_)}))"
#    else "(#{compiler.toCode(@test)}) ? (#{compiler.toCode(@then_)}) : (#{compiler.toCode(@else_)})"
Apply::toCode = (compiler) ->
  "(#{compiler.toCode(@caller)})(#{(compiler.toCode(arg) for arg in @args).join(', ')})"
CApply::toCode = (compiler) -> "(#{compiler.toCode(@caller)})(#{compiler.toCode(@args[0])})"
Begin::toCode = (compiler) ->
  if compiler.parent instanceof Lamda
    compiler.parent = @; "#{(compiler.toCode(exp) for exp in @exps).join('; ')}"
  else
    compiler.parent = @; "{#{(compiler.toCode(exp) for exp in @exps).join('; ')}}"
Print::toCode = (compiler) ->  "console.log(#{(compiler.toCode(exp) for exp in @exps).join(', ')})"
Deref::toCode = (compiler) ->  "solver.trail.deref(#{compiler.toCode(@exp)})"
Code::toCode = (compiler) ->  @string
JSFun::toCode = (compiler) ->  "function() {\n"+\
                               " var args, cont;\n "+\
                               "  cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];\n"+\
                               "   return cont(#{@fun}.apply(this, args));"+\
                               "   }"

isStatement = (exp) ->
  exp_isStatement = exp?.isStatement
  if exp_isStatement then exp_isStatement.call(exp)
  else false

If::isStatement = () -> isStatement(@then_) or isStatement(@else_)
Begin::isStatement = () -> true
Return::isStatement = () -> true
Assign::isStatement = () -> true

il.vari = (name) -> new Var(name)
il.symbol = (name) -> new Symbol(name)
il.assign = (left, exp) -> new Assign(left, exp)
il.if_ = (test, then_, else_) -> new If(test, then_, else_)
il.deref = (exp) -> new Deref(exp)
il.begin = (exps...) ->
  length = exps.length
  if length is 0 then throw new Error "begin should have at least one exp"
  if length is 1 then return exps[0]
  result = []
  for e in exps
    if e instanceof Begin then result = result.concat(e.exps)
    else result.push e
  new Begin(result)
il.print = (exps...) -> new Print(exps)
il.return = (value) -> new Return(value)
il.throw = (value) -> new Throw(value)
il.lamda = (params, body...) -> new Lamda(params, il.begin(body...))
il.clamda = (v, body...) -> new Clamda(v, il.begin(body...))
il.clamdabody = (v, body) -> new ClamdaBody(v, body)
il.idcont = do -> v = il.vari('v'); new IdCont(v, v)
il.code = (string) -> new Code(string)
il.jsfun = (fun) -> new JSFun(fun)

binary = (symbol, func) ->
  class Binary extends BinaryOperation
    symbol: symbol
    toCode: (compiler) -> args = @args; "#{compiler.toCode(args[0])} #{symbol} #{compiler.toCode(args[1])}"
    func; func
  (x, y) -> new Binary([x, y])
unary = (symbol, func) ->
  class Unary extends UnaryOperation
    symbol: symbol
    func; func
    toCode: (compiler) -> "#{symbol}#{compiler.toCode(@args[0])}"
  (x) -> new Unary([x])

il.eq = binary("===", (x, y) -> x is y)
il.ne = binary("!==", (x, y) -> x isnt y)
il.lt = binary("<", (x, y) -> x < y)
il.le = binary("<=", (x, y) -> x <= y)
il.gt = binary(">", (x, y) -> x > y)
il.ge = binary(">=", (x, y) -> x >= y)

il.add = binary("+", (x, y) -> x + y)
il.sub = binary("-", (x, y) -> x - y)
il.mul = binary("*", (x, y) -> x * y)
il.div = binary("/", (x, y) -> x / y)
il.mod = binary("%", (x, y) -> x % y)
il.and_ = binary("&&", (x, y) -> x && y)
il.or_ = binary("||", (x, y) -> x || y)
il.bitand = binary("&", (x, y) -> x & y)
il.bitor = binary("|", (x, y) -> x | y)
il.bitxor = binary("^", (x, y) -> x ^ y)
il.lshift = binary("<<", (x, y) -> x << y)
il.rshift = binary(">>", (x, y) -> x >> y)

augmentAssign = (operator, func) ->
  class AugAssign extends AugmentAssign
    operator: operator
    func: func
  (vari, exp) -> new AugAssign(vari, exp)

il.addassign = augmentAssign("+=", (x, y) -> x + y)
il.subassign = augmentAssign("-=", (x, y) -> x - y)
il.mulassign = augmentAssign("*=", (x, y) -> x * y)
il.divassign = augmentAssign("/=", (x, y) -> x / y)
il.modassign = augmentAssign("%=", (x, y) -> x % y)
il.andassign = augmentAssign("&&=", (x, y) -> x && y)
il.orassign = augmentAssign("||=", (x, y) -> x || y)
il.bitandassign = augmentAssign("&=", (x, y) -> x & y)
il.bitorassign = augmentAssign("|=", (x, y) -> x | y)
il.bitxorassign = augmentAssign("^=", (x, y) -> x ^ y)
il.lshiftassign = augmentAssign("<<=", (x, y) -> x << y)
il.rshiftassign = augmentAssign(">>=", (x, y) -> x >> y)


il.listassign = (lefts..., exp) -> new ListAssign(lefts, exp)

il.not_ = unary("!", (x) -> !x)
il.neg = unary("-", (x) -> -x)
il.bitnot = unary("~", (x) -> ~x)
il.inc = il.effect(unary("++"))
il.dec = il.effect(unary("--"))

vop = (name, toCode, _effect=il.EFFECT) ->
  class Vop extends VirtualOperation
    toCode: toCode
    _effect:_effect
    _name: name
  (args...) -> new Vop(args)

vop2 = (name, toCode, _effect=il.EFFECT) ->
  class Vop extends VirtualOperation
    toCode: toCode
    _effect:_effect
    _name: name
    isStatement: () -> true
  (args...) -> new Vop(args)

il.solver = new Var('solver')
il.array = vop('array', (compiler)->args = @args; "[#{(compiler.toCode(e) for e in args).join(', ')}]")
il.suffixinc = vop('suffixdec', (compiler)->args = @args; "#{compiler.toCode(args[0])}++")
il.suffixdec = vop('suffixdec', (compiler)->args = @args; "#{compiler.toCode(args[0])}--")
il.catches = new Var('solver.catches')
il.pushCatch = vop('pushCatch', (compiler)->args = @args; "solver.pushCatch(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")
il.popCatch = vop('popCatch', (compiler)->args = @args; "solver.popCatch(#{compiler.toCode(args[0])})")
il.findCatch = vop('findCatch', ((compiler)->args = @args; "solver.findCatch(#{compiler.toCode(args[0])})"), il.PURE)
il.fake = vop('fake', (compiler)->args = @args; "solver.fake(#{compiler.toCode(args[0])})").apply([])
il.restore = vop('restore', (compiler)->args = @args; "solver.restore(#{compiler.toCode(args[0])})")
il.getvalue = vop('getvalue', ((compiler)->args = @args; "solver.trail.getvalue(#{compiler.toCode(args[0])})"), il.PURE)
il.list = vop('list', ((compiler)->args = @args; "[#{(compiler.toCode(a) for a in args).join(', ')}]"), il.PURE)
il.length = vop('length', ((compiler)->args = @args; "(#{compiler.toCode(args[0])}).length"), il.PURE)
il.index = vop('index', ((compiler)->args = @args; "(#{compiler.toCode(args[0])})[#{compiler.toCode(args[1])}]"), il.PURE)
il.slice = vop('slice', ((compiler)->args = @args; "#{compiler.toCode(args[0])}.slice(#{compiler.toCode(args[1])}, #{compiler.toCode(args[2])})"), il.PURE)
il.attr = vop('attr', ((compiler)->args = @args; "(#{compiler.toCode(args[0])}).#{compiler.toCode(args[1])}"), il.PURE)
il.push = vop('push', (compiler)->args = @args; "(#{compiler.toCode(args[0])}).push(#{compiler.toCode(args[1])})")
il.concat = vop('concat', ((compiler)->args = @args; "(#{compiler.toCode(args[0])}).concat(#{compiler.toCode(args[1])})"), il.PURE)
il.instanceof = vop('instanceof', ((compiler)->args = @args; "(#{compiler.toCode(args[0])}) instanceof (#{compiler.toCode(args[1])})"), il.PURE)
il.run = vop('run', (compiler)->args = @args; "solver.run(#{compiler.toCode(args[0])})")
il.new = vop('new', (compiler)->args = @args; "new #{compiler.toCode(args[0])}")
il.evalexpr = vop('evalexpr', (compiler)->args = @args; "solve(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")

il.newLogicVar = vop('newLogicVar', ((compiler)->args = @args; "new Var(#{compiler.toCode(args[0])})"), il.PURE)
il.newDummyVar = vop('newDummyVar', ((compiler)->args = @args; "new DummyVar(#{compiler.toCode(args[0])})"), il.PURE)
il.unify = vop('unify', (compiler)->args = @args; "solver.trail.unify(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")
il.bind = vop('bind', (compiler)->args = @args; "#{compiler.toCode(args[0])}.bind(#{compiler.toCode(args[1])}, solver.trail)")

il.undotrail = vop('undotrail', (compiler)->args = @args; "#{compiler.toCode(args[0])}.undo()")
il.failcont = new Var('solver.failcont')
il.setfailcont = (cont) -> il.assign(il.failcont, cont)
il.appendFailcont = vop('appendFailcont', (compiler)->args = @args; "solver.appendFailcont(#{compiler.toCode(args[0])})")
il.cutcont = new Var('solver.cutcont')
il.state = new Var('solver.state')
il.setstate = (state) -> il.assign(il.state, state)
il.trail = new Var('solver.trail')
il.newTrail = vop('newTrail', (compiler)->args = @args; "new Trail()")()
il.settrail = (trail) -> il.assign(il.trail, trail)

il.char = vop('char', ((compiler)->args = @args; "parser.char(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.followChars =  vop('followChars', ((compiler)->args = @args; "parser.followChars(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.notFollowChars = vop('notFollowChars', ((compiler)->args = @args; "parser.notFollowChars(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.charWhen = vop('charWhen', ((compiler)->args = @args; "parser.charWhen(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.spaces = vop('spaces', ((compiler)->args = @args; "parser.spaces(#{compiler.toCode(args[0])})"), il.EFFECT)
il.spaces0 = vop('spaces0', ((compiler)->args = @args; "parser.spaces0(#{compiler.toCode(args[0])})"), il.EFFECT)
il.stringWhile = vop('stringWhile', ((compiler)->args = @args; "parser.stringWhile(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.stringWhile0 = vop('stringWhile0', ((compiler)->args = @args; "parser.stringWhile0(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.number = vop('number', ((compiler)->args = @args; "parser.number(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.literal = vop('literal', ((compiler)->args = @args; "parser.literal(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.followLiteral = vop('followLiteral', ((compiler)->args = @args; "parser.followLiteral(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.notFollowLiteral = vop('notFollowLiteral', ((compiler)->args = @args; "parser.notFollowLiteral(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)
il.quoteString = vop('quoteString', ((compiler)->args = @args; "parser.quoteString(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})"), il.EFFECT)

il.fun = (f) -> new Fun(f)

il.let_ = (bindings, body...) ->
  params = []
  values = []
  for i in [0...bindings.length] by 2
    params.push(bindings[i])
    values.push(bindings[i+1])
  new Apply(il.lamda(params, body...), values)

il.iff = (clauses..., else_) ->
  length = clauses.length
  if length is 2 then il.if_(clauses[0], clauses[1], else_)
  else il.if_(clauses[0], clauses[1], il.iff(clauses[2...length]..., else_))

il.excludes = ['evalexpr', 'failcont', 'run', 'push', 'getvalue', 'fake', 'findCatch', 'popCatch', 'pushCatch', 'protect', 'suffixinc', 'suffixdec', 'dec', 'inc', 'unify', 'bind', 'undotrail', 'newTrail', 'newLogicVar',
 'char', 'followChars', 'notFollowChars', 'charWhen', 'stringWhile', 'stringWhile0', 'number', 'literal', 'followLiteral', 'quoteString']