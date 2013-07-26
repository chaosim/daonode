_ = require("underscore")
{Env, solve} = core = require("./core")

solvecore = require("./solve")
Trail = solvecore.Trail;
LogicVar = solvecore.Var;
DummyVar = solvecore.DummyVar;

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
  isValue: () -> false
  Object.defineProperty @::, '$', get: -> @constructor

class Var extends Element
  constructor: (@name, @suffix='') ->
  toString: () -> @name+@suffix

class UserVar extends Var
class InternalVar extends Var
class BlockVar extends InternalVar
  constructor: (@name, @suffix='') -> super; @convertable = true
class Symbol extends Var

class LocalDecl extends Element
  constructor: (@vars) -> super
  toString: () -> "localDecl(#{@vars}"
  isDeclaration: () -> true

class NonlocalDecl extends LocalDecl
  toString: () -> "nonlocalDecl(#{@vars}"

class Assign extends Element
  constructor: (@left, @exp) -> super; @dependency = []
  toString: () -> "#{toString(@left)} = #{toString(@exp)}"
  remove: () -> @_removed = true
  dont_remove: () -> @_removed = false
  removed: () ->
    if @_removed==true then true
    else if @_removed==false then false
    else
      for item in @dependency
        if item.removed()==false then return false
      true

class AugmentAssign extends Assign
  toString: () -> "#{toString(@left)} #{@operator} #{toString(@exp)}"

class New extends Element
  constructor: (@value) -> super;
  toString: () -> "#{@keyword} #{toString(@value)}"
  keyword: 'new'
class Return extends New
  keyword: 'return'
class Throw extends Return
  keyword: 'throw'
class Begin extends Element
  constructor: (@exps) -> super
  toString: () -> "begin(#{(toString(e) for e in @exps).join(',')})"
  separator: ';'
class ExpressionList extends Begin
  constructor: (@exps) -> super
  toString: () -> "exprlist(#{(toString(e) for e in @exps).join(',')})"
  separator: ','
class Print extends Begin
  toString: () -> "print(#{(toString(e) for e in @exps).join(',')})"
class Lamda extends Element
  constructor: (@params, @body) -> super
  toString: () -> "(#{(toString(e) for e in @params).join(', ')} -> #{toString(@body)})"
  call: (args...) -> new Apply(@, args)
  isValue: () -> true
  apply: (args) -> new Apply(@, args)
il.UserLamda = class UserLamda extends Lamda
class BlockLamda extends Lamda
class OptimizableRecuisiveLamda extends Lamda
class TailRecuisiveLamda extends Lamda
class Clamda extends Lamda
  constructor: (@v, @body) -> @name = @toString(); @params = [v]
  toString: () -> "(#{toString(@v)} -> #{toString(@body)})"
  call: (value) ->
    result = replace(@body, @v.toString(), value)
    if result.constructor is Begin then result.constructor = Begin
    result

class RecursiveClamda extends Clamda
  call: (value) -> new CApply(@, value)

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
  toCode: (compiler) -> args = @args; "#{expressionToCode(compiler, args[0])} #{@symbol} #{expressionToCode(compiler, args[1])}"
  _effect: false
class UnaryOperation extends BinaryOperation
  toString: () -> "#{@symbol}#{toString(@args[0])}"
  toCode: (compiler) -> "#{@symbol}#{expressionToCode(compiler, @args[0])}"
  _effect: false
class Fun extends Element
  constructor: (@func) -> super
  toString: () -> "fun(#{@func})"
  apply: (args) -> new Apply(@, args)
class Apply extends Element
  constructor: (@caller, @args) -> super
  toString: () -> "(#{toString(@caller)})(#{(toString(arg) for arg in @args).join(', ')})"

class Deref extends Element
  constructor: (@exp) -> super
  toString: () -> "deref(#{toString(@exp)})"

class If extends Element
  constructor: (@test, @then_, @else_) -> super
  toString: () -> "if(#{toString(@test)}, #{toString(@then_)}, #{toString(@else_)})"

class LabelStatement extends Element
  constructor: (@label, @statement) -> super
  toString: () -> "#{toString(@label)}: #{toString(@statement)}"

class While extends Element
  constructor: (@test, @body) -> super
  toString: () -> "while(#{toString(@test)}, #{toString(@body)})"
class DoWhile extends While
  constructor: (@test, @body) -> super
  toString: () -> "dowhile(#{toString(@test)}, #{toString(@body)})"
class For extends Element
  constructor: (@init, @test, @step, @body) -> super
  toString: () -> "for(#{toString(@test)}, #{toString(@body)})"
class ForIn extends Element
  constructor: (@vari, @container, @body) -> super
  toString: () -> "forin(#{toString(@vari)}, #{toString(@container)}, #{toString(@body)})"
class ForOf extends Element
  constructor: (@vari, @container, @body) -> super
  toString: () -> "forof(#{toString(@vari)}, #{toString(@container)}, #{toString(@body)})"
class Break extends Element
  constructor: (@label) -> super
  toString: () -> "break #{toString(@label)}"
class Continue extends Break
  toString: () -> "continue #{toString(@label)}"

class Try extends Element
  constructor: (@test, @catches, @final) -> super
  toString: () -> "try(#{toString(@test)}, #{toString(@catches)}, #{toString(@final)})"

replace = (exp, param, value) ->
  exp_replace = exp?.replace
  if exp_replace then exp_replace.call(exp, param, value)
  else exp

Var::replace = (param, value) -> if @toString() is param then value else @
Assign::replace = (param, value) ->
  assign = new @constructor(@left, replace(@exp, param, value))
  if @isParamAssign then assign.isParamAssign = true
  if @root then assign.root = @root
  else assign.root = @
  assign
If::replace = (param, value) ->  new If(replace(@test, param, value), replace(@then_, param, value), replace(@else_, param, value))
LabelStatement::replace = (param, value) ->  new LabelStatement(@label, replace(@statement, param, value))
While::replace = (param, value) ->  new While(replace(@test, param, value), replace(@body, param, value))
For::replace = (param, value) ->  new For(replace(@init, param, value), replace(@test, param, value), replace(@step, param, value), replace(@body, param, value))
ForIn::replace = (param, value) ->  new ForIn(replace(@vari, param, value), replace(@container, param, value), replace(@body, param, value))
Break::replace = (param, value) -> @
Try::replace = (param, value) ->
  catches = ([replace(clause[0], param, value), replace(clause[1], param, value)] for clause in @catches)
  new Try(replace(@test, param, value), replace(catches, param, value), replace(@final, param, value))
New::replace = (param, value) -> new @constructor(replace(@value, param, value))
Lamda::replace = (param, value) -> @ #param should not occur in Lamda
Clamda::replace = (param, value) -> @  #param should not occur in Clamda
IdCont::replace = (param, value) -> @
Apply::replace = (param, value) -> new Apply(replace(@caller, param, value), (replace(a, param, value) for a in @args))
VirtualOperation::replace = (param, value) -> new @constructor((replace(a, param, value) for a in @args))
Begin::replace = (param, value) -> new @constructor((replace(exp, param, value) for exp in @exps))
Deref::replace = (param, value) -> new Deref(value.replace(@exp, param))
JSFun::replace = (param, value) ->  new JSFun(replace(@fun, param, value))

optimize = (exp, env, compiler) ->
  exp_optimize = exp?.optimize
  if exp_optimize then exp_optimize.call(exp, env, compiler)
  else exp

isParam = (vari, lamda) ->
  if lamda instanceof Clamda
    return vari.toString() is lamda.v.toString()
  else
    for param in lamda.params
      if @toString() is param.toString() then return true
    return false

Var::optimize = (env, compiler) ->
  lamda = env.lamda
  if not isParam(@, lamda) then lamda.vars[@] = @
  if @isRecursive then return @
  outerEnv = env.outer
  if outerEnv
    envExp = outerEnv.lookup(@)
    if envExp instanceof Assign then envExp._removed = false
  content = env.lookup(@)
  if content instanceof Assign
    if @isRecursive then @
    else content.exp
  else if _.isArray(content) then @
  else content

Symbol::optimize = (env, compiler) -> @

Assign::optimize = (env, compiler) ->
  lamda = env.lamda
  left = @left
  if left instanceof VirtualOperation
    left = new left.constructor(compiler.optimize(a, env) for a in left.args)
  else
    if left.isConst and left.assigned
      if @root then root = @root
      else root = @
      if left.assigned isnt root # and not (@isParamAssign and left.assigned.isParamAssign)
        throw new Error(@, "should not assign to const more than once.")
    if left instanceof UserVar
      userlamda = env.userlamda
      if userlamda and not isParam(left, userlamda) then userlamda.locals[left] = left
    else
      if not isParam(left, lamda)
        lamda.locals[left] = left
        if left instanceof BlockVar then left.lamda = lamda
  exp = compiler.optimize(@exp, env)
  assign = new @constructor(left, exp)
  assign.root = root
  if @isParamAssign then assign.isParamAssign = true
  left.assigned = assign.root
  if isValue(exp)
    if exp instanceof Lamda and left.isRecursive
      env.bindings[left] = left
      assign._removed = false
    else if not isAtomic(exp)
      env.bindings[left] = left
      assign._removed = false
    else if left instanceof VirtualOperation
      assign._removed = false
    else
      env.bindings[left] = assign
  else if exp instanceof Var and exp.isConst
    env.bindings[left] = assign
    assign._removed = false
  else
    env.bindings[left] = left
    assign._removed = false
  assign

LocalDecl::optimize = (env, compiler) ->
  for vari in @vars
    if vari instanceof UserVar then env.userlamda.locals[vari] = vari
    else env.lamda.locals[vari] = vari
  @

NonlocalDecl::optimize = (env, compiler) ->
  for vari in @vars
    if vari instanceof UserVar then env.userlamda.nonlocals[vari] = vari
    else env.lamda.nonlocals[vari] = vari
  @

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

LabelStatement::optimize = (env, compiler) ->  new LabelStatement(@label, optimize(@statement, env, compiler))

While::optimize = (env, compiler) ->
  test = optimize(@test, env, compiler)
  new While(test, @body)

For::optimize = (env, compiler) ->
  init = optimize(@init, env, compiler)
  test = optimize(@test, env, compiler)
  step = optimize(@step, env, compiler)
  body = optimize(@body, env, compiler)
  new For(init, test, step, body)

ForIn::optimize = (env, compiler) ->
  new ForIn(optimize(@vari, env, compiler), test = optimize(container, env, compiler), optimize(@body, env, compiler))

Break::optimize = (env, compiler) -> @
Try::optimize = (env, compiler) ->
  test = optimize(@test, env, compiler)
  new Try(test, @catches, @final)

New::optimize = (env, compiler) -> new @constructor(compiler.optimize(@value, env))
Lamda::optimize = (env, compiler) ->
  parentLamda = env.lamda
  parentBindings = env.bindings
  if @_optimized and not @isTransparent
    if parentLamda
      vars = @vars
      for k, v of vars
        if hasOwnProperty.call(vars, k)
          envValue = parentBindings[k]
          if envValue instanceof Assign then envValue._removed = false
    return @
  bindings = {}
  for p in @params then bindings[p] = p
  @locals = locals = {}; @nonlocals = nonlocals = {}; @vars = vars = {}
  if @isTransparent then newEnv = newEnv = env.extendBindings(null, @)
  else newEnv = env.extendBindings(bindings, @)
  body = compiler.optimize(@body, newEnv)
  for k, v of vars
    if hasOwnProperty.call(vars, k) and hasOwnProperty.call(locals, k)
      delete vars[k]
  for k, v of nonlocals
    if hasOwnProperty.call(nonlocals, k)
      vars[k] = v
  if not @isTransparent and parentLamda
    parentVars = parentLamda.vars
    for k, v of vars
      if hasOwnProperty.call(vars, k)
        if not isParam(v, parentLamda) then parentVars[k] = v
        envValue = parentBindings[k]
        if envValue instanceof Assign then envValue._removed = false
  @body = postOptimize(body, compiler, newEnv)
  @_optimized = true
  return @

IdCont::optimize = (env, compiler) -> @

Apply::optimize = (env, compiler) ->
  caller =  compiler.optimize(@caller, env)
  optimizeApply = caller.optimizeApply
  if optimizeApply then optimizeApply.call(caller, @args, env, compiler)
  else
    if caller instanceof BlockVar and env.lamda isnt caller.lamda and env.lamda not instanceof BlockLamda
      caller.convertable = false
    new Apply(caller, (compiler.optimize(a, env) for a in @args))

VirtualOperation::optimize = (env, compiler) ->
  args = (compiler.optimize(a, env) for a in @args)
  _isValue = true
  for a in args
    if not isValue(a) then _isValue = false; break
  if _isValue and @func then @func.apply(null, args)
  else new @constructor(args)

Begin::optimize = (env, compiler) ->
  result = []
  for exp in @exps
    e = compiler.optimize(exp, env)
    if e instanceof Begin then result = result.concat(e.exps)
    else result.push e
    if e instanceof Throw or e instanceof Return then break
  if result.length>1 then  new @constructor(result)
  else result[0]
Deref::optimize = (env, compiler) ->
  exp = @exp
  if _.isString(exp) then exp
  else if _.isNumber(exp) then exp
  else new Deref(compiler.optimize(exp, env))
JSFun::optimize = (env, compiler) ->  new JSFun(compiler.optimize(@fun, env))

Lamda::optimizeApply = (args, env, compiler) ->
  exps = (il.paramassign(p, args[i]) for p, i in @params)
  exps.push @body
  body = compiler.optimize(il.begin(exps...), env)
  body = postOptimize(body, compiler, env)
  if not isStatement(body) then body
  else
    lamda = new @constructor([], body)
    lamda._optimized = true
    new Apply(lamda, [])

Clamda::optimizeApply = (args, env, compiler) ->
  il.begin(il.paramassign(@v, args[0]), @body).optimize(env, compiler)

RecursiveClamda::optimizeApply = (args, env, compiler) ->
  il.begin(il.paramassign(@v, args[0]), @body).optimize(env, compiler)

IdCont::optimizeApply = (args, env, compiler) -> compiler.optimize(args[0], env)

JSFun::optimizeApply = (args, env, compiler) ->
  args = (compiler.optimize(a, env) for a in args)
  f = @fun
  t = typeof f
  if t is 'function' then new Apply(f, args)
  else if t is 'string' then new Apply(il.fun(f), args)
  else f.apply(args).optimize(env, compiler)

MAX_EXTEND_CODE_SIZE = 10

hasOwnProperty = Object::hasOwnProperty
isEmpty = (obj) ->
  for key of obj  then if hasOwnProperty.call(obj, key) then return false
  return true

codeSize = (exp) ->
  exp_codeSize = exp?.codeSize
  if exp_codeSize then exp_codeSize.call(exp)
  else 1

Var::codeSize = () -> 1
New::codeSize = () -> codeSize(@value)+1
If::codeSize = () -> codeSize(@test) + codeSize(@then_) + codeSize(@else_) + 1
LabelStatement::codeSize = () -> codeSize(@statement)
For::codeSize = () -> codeSize(@init) + codeSize(@test) + codeSize(@step) + codeSize(@body)+2
ForIn::codeSize = () -> codeSize(@vari) + codeSize(@container) + codeSize(@body)+2
While::codeSize = () -> codeSize(@test) + codeSize(@body)+2
Break::codeSize = () -> 1
Try::codeSize = () -> codeSize(@test) + codeSize(@catches)+codeSize(@final)+2
Begin::codeSize = () -> _.reduce(@exps, ((memo, e) -> memo + codeSize(e)), 0)
VirtualOperation::codeSize = () -> 1
Lamda::codeSize = () -> codeSize(@body) + 2
Clamda::codeSize = () -> codeSize(@body) + 1
Apply::codeSize = () -> _.reduce(@args, ((memo, e) -> memo + codeSize(e)), codeSize(@caller))

boolize = (exp) ->
  exp_boolize = exp?.boolize
  if exp_boolize then exp_boolize.call(exp)
  else !!exp

Var::boolize = () -> undefined
If::boolize = () ->
  b = boolize(@test)
  if b is undefined then undefined
  if b is true then boolize(@then_) else boolize(@else_)
LabelStatement::boolize = () -> boolize(@statement)
For::boolize = () -> undefined
ForIn::boolize = () -> undefined
While::boolize = () -> undefined
Try::boolize = () -> undefined
Break::boolize = () -> undefined
Begin::boolize = () -> exps = @exps; boolize(exps[exps.length-1])
VirtualOperation::boolize = () ->
  for a in @args then if boolize(a) is undefined then return undefined
  !!(@func?.apply(null, @args)) or undefined
Lamda::boolize = () -> true
Clamda::boolize = () -> true
Apply::boolize = () ->
  caller = @caller
  if caller instanceof Lamda or caller instanceof Clamda then return boolize(caller.body)
  if caller instanceof Var then return undefined
  for a in @args then if boolize(a) is undefined then return undefined
  !!(caller.func?.apply(null, @args)) or undefined

isDeclaration  = (exp) ->
  exp_isDeclaration = exp?.isDeclaration
  if exp_isDeclaration then exp_isDeclaration.call(exp)
  else false

isValue = (exp) ->
  exp_isValue = exp?.isValue
  if exp_isValue then exp_isValue.call(exp)
  else true

isAtomic = (exp) -> not _.isObject(exp)

il.PURE = 0; il.EFFECT = 1; il.IO = 2
il.pure = pure = (exp) -> exp._effect = il.PURE; exp
il.effect = (exp) -> exp._effect = il.EFFECT; exp
il.io = (exp) -> exp._effect = il.IO; exp

sideEffect = (exp) ->
  exp_sideEffect = exp?.sideEffect
  if exp_sideEffect then exp_sideEffect.call(exp)
  else il.PURE

expsEffect = (exps) ->
  effect = il.PURE
  for e in exps
    eff = sideEffect(e)
    if eff == il.IO then return il.IO
    if eff == il.EFFECT then effect = eff
  effect

Element::sideEffect = () -> il.IO
Var::sideEffect = () -> il.PURE
NonlocalDecl::sideEffect = () -> il.PURE
Assign::sideEffect = () -> il.EFFECT
New::sideEffect = () -> sideEffect(@value)
Throw::sideEffect = () -> il.IO
New::sideEffect = () -> sideEffect(@value)
If::sideEffect = () -> expsEffect [@test, @then_, @else_]
LabelStatement::sideEffect = () -> sideEffect(@statement)
For::sideEffect = () -> expsEffect [@init, @test, @step, @body]
ForIn::sideEffect = () -> expsEffect [@container, @body]
While::sideEffect = () -> expsEffect [@test, @body]
Break::sideEffect = () -> il.EFFECT
Try::sideEffect = () -> expsEffect [@test, @catches, @final]
Begin::sideEffect = () -> expsEffect(@exps)
Lamda::sideEffect = () ->  il.PURE
JSFun::sideEffect = () ->  il.PURE
Fun::sideEffect = () ->  il.PURE
Apply::sideEffect = () ->  Math.max(applySideEffect(@caller), expsEffect(@args))
VirtualOperation::sideEffect = () ->  Math.max(@_effect, expsEffect(@args))

applySideEffect = (exp) ->
  exp_applySideEffect = exp?.applySideEffect
  if exp_applySideEffect then exp_applySideEffect.call(exp)
  else il.IO

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

postOptimize = (exp, compiler, env) ->
  exp_postOptimize = exp?.postOptimize
  if exp_postOptimize then exp_postOptimize.call(exp, compiler, env)
  else exp

Assign::postOptimize = (compiler, env) -> @
If::postOptimize = (compiler, env) ->
  new If(@test, postOptimize(@then_, compiler, env), postOptimize(@else_, compiler, env))
LabelStatement::postOptimize = (compiler, env) ->  @
While::postOptimize = (compiler, env) ->
  new While(@test, postOptimize(@body, compiler, env))
For::postOptimize = (compiler, env) ->
  new For(postOptimize(@init, compiler, env), postOptimize(@test, compiler, env), postOptimize(@step, compiler, env), postOptimize(@body, compiler, env))
ForIn::postOptimize = (compiler, env) ->
  new ForIn(@vari, @container, postOptimize(@body, compiler, env))
Break::postOptimize = (compiler, env) -> @
Try::postOptimize = (compiler, env) ->
  new Try(postOptimize(@test, compiler, env), postOptimize(@catches, compiler, env), postOptimize(@final, compiler, env))

Begin::postOptimize = (compiler, env) ->
  exps = @exps
  length = exps.length
  if length is 0 or length is 1
    throw new  Error "begin should have at least one exp"
  result = []
  waitPop = false
  for e in exps
    if e instanceof Assign and e.removed() then continue
    if waitPop then result.pop()
    e = postOptimize(e, compiler, env)
    if e instanceof Begin
      result = result.concat e.exps
      waitPop = sideEffect(result[result.length-1]) is il.PURE
#    else if e instanceof LocalDecl then continue # include NonlocalDecl
    else if e instanceof Throw then result.push e; break
    else if e instanceof Return then throw new Error(e)
    else result.push(e); waitPop = sideEffect(e) is il.PURE
  if result.length==1 then result[0]
  else new @constructor(result)

Lamda::postOptimize = (compiler, env) -> @
Apply::postOptimize = (compiler, env) -> @
VirtualOperation::postOptimize = (compiler, env) -> @

setJsified = (exp) -> exp?._jsified = true; exp
isJsified = (exp) -> exp?._jsified or false

jsify = (exp, compiler, env) ->
  if isJsified(exp) then return exp
  exp_jsify = exp?.jsify
  if exp_jsify then exp_jsify.call(exp, compiler, env)
  else exp

Assign::jsify = (compiler, env) ->
  if @_jsified then return @
  left = @left; exp = jsify(@exp, compiler, env)
  if left instanceof BlockVar and left.convertable
    return il.label(left, il.while_(1, convertBlockLamdaBody(exp.body, left)))
  else
    if exp instanceof OptimizableRecuisiveLamda
      params = exp.params
      length = params.length
      exp.vari = left
      if length>1
        exp.tempParams = tempParams = (params[i] for i in [0...length])
        getConvertParameters(exp.body, compiler, exp)
        body = convertOptRecursive(exp.body, exp)
        exps = [body]
        for i in [0...length]
          if tempParams[i] isnt params[i]
            exps.push(il.assign(params[i], tempParams[i]))
        body = il.begin(exps...)
      else body = convertOptRecursive(exp.body, exp)
      exp.body = il.begin(exp.init, il.while_(1, body))
    if exp instanceof TailRecuisiveLamda
      params = exp.params
      length = params.length
      exp.vari = left
      if length>1
        exp.tempParams = tempParams = (params[i] for i in [0...length])
        getConvertParameters(exp.body, compiler, exp)
        body = convertTailRecursive(exp.body, exp)
        exps = [body]
        for i in [0...length]
          if tempParams[i] isnt params[i]
            exps.push(il.assign(params[i], tempParams[i]))
        body = il.begin(exps...)
      else body = convertTailRecursive(exp.body, exp)
      exp.body = il.while_(1, body)
  result = new Assign(left, exp)
  if @root then result.root = @root
  else result.root = @
  result._jsified = true
  result

New::jsify = (compiler, env) ->  new @constructor(jsify(@value, compiler, env))
If::jsify = (compiler, env) ->
  new If(jsify(@test, compiler, env), jsify(@then_, compiler, env), jsify(@else_, compiler, env))
LabelStatement::jsify = (compiler, env) ->  new LabelStatement(@label, jsify(@statement, compiler, env))
While::jsify = (compiler, env) ->
  new While(jsify(@test, compiler, env), jsify(@body, compiler, env))
For::jsify = (compiler, env) ->
  new For(jsify(@init, compiler, env), jsify(@test, compiler, env), jsify(@step, compiler, env), jsify(@body, compiler, env))
ForIn::jsify = (compiler, env) ->
  new ForIn(jsify(@vari, compiler, env), jsify(@container, compiler, env), jsify(@body, compiler, env))
Break::jsify = (compiler, env) -> @
Try::jsify = (compiler, env) ->
  new Try(jsify(@test, compiler, env), jsify(@catches, compiler, env), jsify(@final, compiler, env))

Begin::jsify = (compiler, env) ->
  exps = @exps
  length = exps.length
  if length is 0 or length is 1
    throw new  Error "begin should have at least one exp"
  result = []
  waitPop = false
  for e in exps
    if waitPop then result.pop()
    e = jsify(e, compiler, env)
    if e instanceof Begin
      result = result.concat e.exps
      waitPop = sideEffect(result[result.length-1]) is il.PURE
    else if e instanceof LocalDecl then continue # include NonlocalDecl
    else if e instanceof New
      result.push e
      waitPop = sideEffect(e) is il.PURE
    else if e instanceof Throw then result.push e; break
    else if e instanceof Return then throw new Error(e)
    else result.push(e); waitPop = sideEffect(e) is il.PURE
  if result.length==1 then result[0]
  else new @constructor(result)

Lamda::jsify = (compiler, env) ->
  if not @_jsifyied
    lamda = env.lamda
    env.lamda = @
    body = jsify(@body, compiler, env)
    env.lamda = lamda
    @body = insertReturn(body)
    @_jsifyied = true
  @

Apply::jsify = (compiler, env) ->
  caller = @caller
  if caller instanceof Lamda and caller.params.length is 0
    body = jsify(caller.body, compiler, env)
    if not isStatement(body) then body
    else
      new Apply(new caller.constructor([], insertReturn(body)), [])
  else
    if caller instanceof BlockVar and caller.convertable and caller.lamda is env.lamda
      caller
    else new @constructor(jsify(@caller, compiler, env), (jsify(a, compiler, env) for a in @args))

VirtualOperation::jsify = (compiler, env) -> new @constructor(jsify(a, compiler, env) for a in @args)

convertBlockLamdaBody = (exp, blockvar) ->
  exp_convertBlockLamdaBody = exp?.convertBlockLamdaBody
  if exp_convertBlockLamdaBody then exp_convertBlockLamdaBody.call(exp, blockvar)
  else exp

Assign::convertBlockLamdaBody = (blockvar) -> @
If::convertBlockLamdaBody = (blockvar) -> new If(@test, convertBlockLamdaBody(@then_, blockvar), convertBlockLamdaBody(@else_, blockvar))
LabelStatement::convertBlockLamdaBody = (blockvar) -> new LabelStatement(@label, convertBlockLamdaBody(@statement, blockvar))
While::convertBlockLamdaBody = (blockvar) -> new While(@test, convertBlockLamdaBody(@body, blockvar))
Break::convertBlockLamdaBody = (blockvar) -> @
Try::convertBlockLamdaBody = (blockvar) ->
  new Try(convertBlockLamdaBody(@test, blockvar), convertBlockLamdaBody(@catches, blockvar), convertBlockLamdaBody(@final, blockvar))
Begin::convertBlockLamdaBody = (blockvar) ->
  exps = []
  for e in @exps
    exps.push(convertBlockLamdaBody e, blockvar)
  new @constructor(exps)
Throw::convertBlockLamdaBody = (blockvar) -> @
Return::convertBlockLamdaBody = (blockvar) ->
  value = @value
  if value instanceof Apply and value.caller is blockvar
    il.continue_(blockvar)
  else if value instanceof BlockVar then @
  else new Begin([il.assign(blockvar, @value), il.break_(blockvar)])

Lamda::convertBlockLamdaBody = (blockvar) ->
  @body = convertBlockLamdaBody(@body, blockvar)
  @
Apply::convertBlockLamdaBody = (blockvar) -> @

convertOptRecursive = (exp, lamda) ->
  exp_convertOptRecursive = exp?.convertOptRecursive
  if exp_convertOptRecursive then exp_convertOptRecursive.call(exp, lamda)
  else exp

Assign::convertOptRecursive = (lamda) -> @
If::convertOptRecursive = (lamda) -> new If(@test, convertOptRecursive(@then_, lamda), convertOptRecursive(@else_, lamda))
LabelStatement::convertOptRecursive = (lamda) -> new LabelStatement(@label, convertOptRecursive(@statement, lamda))
While::convertOptRecursive = (lamda) -> new While(@test, convertOptRecursive(@body, lamda))
Break::convertOptRecursive = (lamda) -> @
Try::convertOptRecursive = (lamda) ->
  new Try(convertOptRecursive(@test, lamda), convertOptRecursive(@catches, lamda), convertOptRecursive(@final, lamda))
Begin::convertOptRecursive = (lamda) ->
  exps = []
  for e in @exps
    exps.push(convertOptRecursive e, lamda)
  new @constructor(exps)
Throw::convertOptRecursive = (lamda) -> @
Return::convertOptRecursive = (lamda) ->
  value = @value
  if value instanceof If
    then_ = insertReturn(value.then_)
    then_ = convertOptRecursive(then_, lamda)
    else_ = insertReturn(value.else_)
    else_ = convertOptRecursive(else_, lamda)
    new If(value.test, then_, else_)
  else if hasCallOf(value, lamda.vari)
    steps = []
    result = convertOptResursiveCall(value, lamda, steps)
    if result is lamda.vari
      il.begin(steps...)
    else il.begin(il.assign(lamda.vari, result), steps)
  else
    lamda.init = il.assign(lamda.vari, value)
    new Return(lamda.vari)

Lamda::convertOptRecursive = (lamda) -> @
Apply::convertOptRecursive = (lamda) -> @

convertOptResursiveCall = (exp, lamda, steps)  ->
  exp_convertOptResursiveCall = exp?.convertOptResursiveCall
  if exp_convertOptResursiveCall then exp_convertOptResursiveCall.call(exp, lamda, steps) 
  else false

Assign::convertOptResursiveCall = (lamda, steps)  -> new Assign(@left, convertOptResursiveCall(@exp, lamda, steps))
If::convertOptResursiveCall = (lamda, steps)  ->
  new If(@test, convertOptResursiveCall(@then_, lamda, steps), convertOptResursiveCall(@else_, lamda, steps))
LabelStatement::convertOptResursiveCall = (lamda, steps)  -> throw new Error(@)
While::convertOptResursiveCall = (lamda, steps)  -> throw new Error(@)
Break::convertOptResursiveCall = (lamda, steps)  -> throw new Error(@)
Try::convertOptResursiveCall = (lamda, steps)  ->
  new Try(convertOptResursiveCall(@test, lamda, steps),\
          convertOptResursiveCall(@catches, lamda, steps),\
          convertOptResursiveCall(@final, lamda, steps))
Begin::convertOptResursiveCall = (lamda, steps)  -> throw new Error(@)
ExpressionList::convertOptResursiveCall = (lamda, steps)  ->
  exps = []
  for e in @exps
    exps.push(convertOptResursiveCall e, lamda, steps)
  new @constructor(exps)
Throw::convertOptResursiveCall = (lamda, steps)  ->  throw new Error(@)
Return::convertOptResursiveCall = (lamda, steps)  -> throw new Error(@)
Lamda::convertOptResursiveCall = (lamdavar) -> throw new Error(@)
Apply::convertOptResursiveCall = (lamda, steps)  ->
  if @caller is lamda.vari
    params = lamda.params
    args = @args
    for i in [0...args.length]
      a = args[i]
      param = params[i]
      if a.toString() isnt param
        steps.push(new Assign(param, a))
    lamda.vari
  else new Apply(convertOptResursiveCall(a, lamda, steps) for a in @args)

VirtualOperation::convertOptResursiveCall = (lamda, steps)  ->
  new @constructor(convertOptResursiveCall(a, lamda, steps) for a in @args)

convertTailRecursive = (exp, lamda) ->
  exp_convertTailRecursive = exp?.convertTailRecursive
  if exp_convertTailRecursive then exp_convertTailRecursive.call(exp, lamda)
  else exp

Assign::convertTailRecursive = (lamda) -> @
If::convertTailRecursive = (lamda) -> new If(@test, convertTailRecursive(@then_, lamda), convertTailRecursive(@else_, lamda))
LabelStatement::convertTailRecursive = (lamda) -> new LabelStatement(@label, convertTailRecursive(@statement, lamda))
While::convertTailRecursive = (lamda) -> new While(@test, convertTailRecursive(@body, lamda))
Break::convertTailRecursive = (lamda) -> @
Try::convertTailRecursive = (lamda) ->
  new Try(convertTailRecursive(@test, lamda), convertTailRecursive(@catches, lamda), convertTailRecursive(@final, lamda))
Begin::convertTailRecursive = (lamda) ->
  exps = []
  for e in @exps
    exps.push(convertTailRecursive e, lamda)
  new @constructor(exps)
Throw::convertTailRecursive = (lamda) -> @
Return::convertTailRecursive = (lamda) ->
  value = @value
  if value instanceof If
    then_ = insertReturn(value.then_)
    then_ = convertTailRecursive(then_, lamda)
    else_ = insertReturn(value.else_)
    else_ = convertTailRecursive(else_, lamda)
    new If(value.test, then_, else_)
  else if hasCallOf(value, lamda.vari)
    steps = []
    result = convertTailResursiveCall(value, lamda, steps)
    if result is lamda.vari
      il.begin(steps...)
    else il.begin(il.assign(lamda.vari, result), steps)
  else
    @

Lamda::convertTailRecursive = (lamda) -> @
Apply::convertTailRecursive = (lamda) -> @

convertTailResursiveCall = (exp, lamda, steps)  ->
  exp_convertTailResursiveCall = exp?.convertTailResursiveCall
  if exp_convertTailResursiveCall then exp_convertTailResursiveCall.call(exp, lamda, steps)
  else false

Assign::convertTailResursiveCall = (lamda, steps)  -> new Assign(@left, convertTailResursiveCall(@exp, lamda, steps))
If::convertTailResursiveCall = (lamda, steps)  ->
  new If(@test, convertTailResursiveCall(@then_, lamda, steps), convertTailResursiveCall(@else_, lamda, steps))
LabelStatement::convertTailResursiveCall = (lamda, steps)  -> throw new Error(@)
While::convertTailResursiveCall = (lamda, steps)  -> throw new Error(@)
Break::convertTailResursiveCall = (lamda, steps)  -> throw new Error(@)
Try::convertTailResursiveCall = (lamda, steps)  ->
  new Try(convertTailResursiveCall(@test, lamda, steps),\
          convertTailResursiveCall(@catches, lamda, steps),\
          convertTailResursiveCall(@final, lamda, steps))
Begin::convertTailResursiveCall = (lamda, steps)  -> throw new Error(@)
ExpressionList::convertTailResursiveCall = (lamda, steps)  ->
  exps = []
  for e in @exps
    exps.push(convertTailResursiveCall e, lamda, steps)
  new @constructor(exps)
Throw::convertTailResursiveCall = (lamda, steps)  ->  throw new Error(@)
Return::convertTailResursiveCall = (lamda, steps)  -> throw new Error(@)
Lamda::convertTailResursiveCall = (lamdavar) -> throw new Error(@)
Apply::convertTailResursiveCall = (lamda, steps)  ->
  if @caller is lamda.vari
    params = lamda.tempParams
    args = @args
    for i in [0...args.length]
      a = args[i]
      param = params[i]
      if a.toString() isnt param
        steps.push(new Assign(param, a))
    lamda.vari
  else new Apply(convertTailResursiveCall(a, lamda, steps) for a in @args)

VirtualOperation::convertTailResursiveCall = (lamda, steps)  ->
  new @constructor(convertTailResursiveCall(a, lamda, steps) for a in @args)

getConvertParameters = (exp, compiler, lamda) ->
  exp_getConvertParameters = exp?.getConvertParameters
  if exp_getConvertParameters then exp_getConvertParameters.call(exp, compiler, lamda)

Assign::getConvertParameters = (compiler, lamda) -> getConvertParameters(@exp, compiler, lamda)
If::getConvertParameters = (compiler, lamda) ->
  getConvertParameters(@then_, compiler, lamda)
  getConvertParameters(@else_, compiler, lamda)
LabelStatement::getConvertParameters = (compiler, lamda) -> getConvertParameters(@body, compiler, lamda)
While::getConvertParameters = (compiler, lamda) ->
  getConvertParameters(@test, compiler, lamda)
  getConvertParameters(@body, compiler, lamda)
Break::getConvertParameters = (compiler, lamda) -> @
Try::getConvertParameters = (compiler, lamda) ->
  getConvertParameters(@test, compiler, lamda)
  getConvertParameters(@catches, compiler, lamda)
  getConvertParameters(@final, compiler, lamda)
Begin::getConvertParameters = (compiler, lamda) -> getConvertParameters e, compiler, lamda
New::getConvertParameters = (compiler, lamda) -> getConvertParameters @value, compiler, lamda
Lamda::getConvertParameters = (varivar) ->
Apply::getConvertParameters = (compiler, lamda) ->
  caller = @caller
  if caller is lamda.vari
    params = lamda.params; tempParams = lamda.tempParams
    length = params.length
    args = @args
    for i in [1...length]
      useConvertParams(args[i],  params[0...i])
    for i in [0...length]
      if params[i].usedConvertParam
        tempParams[i] = compiler.newvar(params[i])
        lamda.locals[tempParams[i]] = true
  else
    getConvertParameters(caller, compiler, lamda)
    for a in @args
      getConvertParameters(a, compiler, lamda)

VirtualOperation::getConvertParameters = (compiler, lamda) ->
  for a in @args then getConvertParameters(a, compiler, lamda)

useConvertParams = (exp, vars) ->
  exp_useConvertParams = exp?.useConvertParams
  if exp_useConvertParams then exp_useConvertParams.call(exp, vars)
  else false

Assign::useConvertParams = (vars) -> useConvertParams(@exp, vars)
Var::useConvertParams = (vars) ->
  for v in vars
    if v is @ then v.usedConvertParam = true; return
If::useConvertParams = (vars) ->
  useConvertParams(@test, vars)
  useConvertParams(@then_, vars)
  useConvertParams(@else_, vars)
LabelStatement::useConvertParams = (vars) -> throw new Error(@)
While::useConvertParams = (vars) -> throw new Error(@)
Break::useConvertParams = (vars) -> throw new Error(@)
Try::useConvertParams = (vars) -> throw new Error(@)
Begin::useConvertParams = (vars) -> throw new Error(@)
ExpressionList::useConvertParams = (vars) -> useConvertParams e, vars
Throw::useConvertParams = (vars) ->  throw new Error(@)
Return::useConvertParams = (vars) -> throw new Error(@)
Lamda::useConvertParams = (varivar) ->
Apply::useConvertParams = (vars) ->
  useConvertParams(@caller, vars)
  for a in @args
    useConvertParams(a, vars)
VirtualOperation::useConvertParams = (vars) ->
  for a in @args
    useConvertParams(a, vars)

hasCallOf = (exp, vari) ->
  exp_hasCallOf = exp?.hasCallOf
  if exp_hasCallOf then exp_hasCallOf.call(exp, vari)
  else false

Assign::hasCallOf = (vari) -> @
If::hasCallOf = (vari) -> hasCallOf(@then_, vari) or hasCallOf(@else_, vari)
LabelStatement::hasCallOf = (vari) -> throw new Error(@)
While::hasCallOf = (vari) -> throw new Error(@)
Break::hasCallOf = (vari) -> @
Try::hasCallOf = (vari) ->
  new Try(hasCallOf(@test, vari), hasCallOf(@catches, vari), hasCallOf(@final, vari))
Begin::hasCallOf = (vari) -> throw new Error(@)
ExpressionList::hasCallOf = (vari) ->
  exps = []
  for e in @exps
    exps.push(hasCallOf e, vari)
  new @constructor(exps)
Throw::hasCallOf = (vari) ->  false
Return::hasCallOf = (vari) -> throw new Error(@)
Lamda::hasCallOf = (varivar) -> false
Apply::hasCallOf = (vari) ->
  if @caller is vari then true
  else
    for a in @args
      if hasCallOf(a, vari) then return true
    return false

VirtualOperation::hasCallOf = (vari) ->
  for a in @args
    if hasCallOf(a, vari) then return true
  return false

il.insertReturn = insertReturn = (exp) ->
  exp_insertReturn = exp?.insertReturn
  if exp_insertReturn then exp_insertReturn.call(exp)
  else new Return(exp)

Assign::insertReturn = () -> il.begin(@, il.return(@left))
New::insertReturn = () -> new Return(@)
Throw::insertReturn = () -> @
Return::insertReturn = () -> @

If::insertReturn = () ->
  if @isStatement() then new If(@test, insertReturn(@then_), insertReturn(@else_))
  else new Return(@)
LabelStatement::insertReturn = () -> new LabelStatement(@label, insertReturn(@statement))
While::insertReturn = () ->
  new Begin(new While(@test, insertReturn(@body)), new Return())
Break::insertReturn = () -> @
Try::insertReturn = () -> new Try(@test, insertReturn(@catches), insertReturn(@final))
Begin::insertReturn = () ->
  exps = @exps
  length = exps.length
  last = insertReturn(exps[length-1])
  new @constructor([exps[0...length-1]..., last])

Lamda::toCode = (compiler) ->
  locals = []
  nonlocals = @nonlocals
  locals1 = @locals
  for k of locals1
    if not hasOwnProperty.call(nonlocals, k) and k not in @params then locals.push(il.symbol(k))
  body = @body
  if locals.length>0 then body = il.begin(il.vardecl(locals...), @body)
  if body instanceof Begin then body.constructor = Begin
  "function(#{(a.toString() for a in @params).join(', ')}){#{compiler.toCode(body)}}"

Fun::toCode = (compiler) -> @func.toString()
New::toCode = (compiler) -> "#{@keyword} #{compiler.toCode(@value)}"
Var::toCode = (compiler) -> @toString()
NonlocalDecl::toCode = (compiler) -> ''
Assign::toCode = (compiler) ->
  exp = @exp
  left = compiler.toCode(@left)
  if exp instanceof BinaryOperation
    args = exp.args
    args0 = compiler.toCode(args[0])
    args1 = compiler.toCode(args[1])
    if left == args0
      symbol = exp.symbol
      switch symbol
        when '+'
          if args1=='1' then "++#{left}"
          else return "#{left} += #{args1}"
        when '-'
          if args1=='1' then "--#{left}"
          else "#{left} -= #{args1}"
        when '*', '/', '%', '|', '&', '^', '||', '&&', '<<', '>>'
          "#{left} #{symbol}= #{args1}"
        else "#{left} = #{args0} #{symbol} #{args1}"
    else "#{left} = #{args0} #{exp.symbol} #{args1}"
  else "#{left} = #{compiler.toCode(exp)}"

AugmentAssign::toCode = (compiler) -> "#{compiler.toCode(@left)} #{@operator} #{compiler.toCode(@exp)}"
If::toCode = (compiler) ->
  compiler.parent = @
  then_ = @then_; else_ = @else_
  if @isStatement()
    if then_ instanceof Begin then thenBody = "{#{compiler.toCode(then_)}}"
    else thenBody = "#{compiler.toCode(then_)};"
    if else_ is undefined then "if (#{compiler.toCode(@test)}) "+thenBody
    else
      if else_ instanceof Begin then elseBody = "{#{compiler.toCode(else_)}}"
      else elseBody = "#{compiler.toCode(else_)}"
      "if (#{compiler.toCode(@test)}) #{thenBody}else #{elseBody}"
  else
    "(#{compiler.toCode(@test)}) ? #{expressionToCode(compiler, @then_)} : #{expressionToCode(compiler, @else_)}"
LabelStatement::toCode = (compiler) ->  "#{compiler.toCode(@label)}:#{compiler.toCode(@statement)}"
For::toCode = (compiler) ->
  "for (#{compiler.toCode(@init)};#{compiler.toCode(@test)};#{compiler.toCode(@step)}){#{compiler.toCode(@body)}}"
ForIn::toCode = (compiler) ->
  "for (#{compiler.toCode(@vari)} in #{compiler.toCode(@container)}){#{compiler.toCode(@body)}}"
ForOf::toCode = (compiler) ->
  "for (#{compiler.toCode(@vari)} of #{compiler.toCode(@container)}){#{compiler.toCode(@body)}}"
While::toCode = (compiler) ->
  "while (#{compiler.toCode(@test)}){#{compiler.toCode(@body)}}"
DoWhile::toCode = (compiler) ->
  "do{#{compiler.toCode(@body)}}while(#{compiler.toCode(@test)}) "
Try::toCode = (compiler) ->
  "try{ #{compiler.toCode(@test)}} #{compiler.toCode(@catches)} finally{#{compiler.toCode(@final)}}"
Break::toCode = (compiler) ->
  if @label then "break #{compiler.toCode(@label)}"
  else "break"
Continue::toCode = (compiler) ->
  if @label then "continue #{compiler.toCode(@label)}"
  else "continue"
Apply::toCode = (compiler) ->
  caller = @caller
  "#{expressionToCode(compiler, caller)}(#{(compiler.toCode(arg) for arg in @args).join(', ')})"
Begin::toCode = (compiler) ->
  result = ''
  exps = @exps
  length = exps.length
  i = 0
  while i<length-1
    code = compiler.toCode(exps[i++]);
    if code is '' then continue
    else result += code + @separator
  result += compiler.toCode(exps[i])
  result += ''
  result
Deref::toCode = (compiler) ->  "solver.trail.deref(#{compiler.toCode(@exp)})"
JSFun::toCode = (compiler) ->  if _.isString(@fun) then @fun  else compiler.toCode(@fun)

Assign::needParenthesis = true
BinaryOperation::needParenthesis = true
UnaryOperation::needParenthesis = true
ExpressionList::needParenthesis = true
Lamda::needParenthesis = true

expressionToCode = (compiler, exp) ->
  if not exp.needParenthesis and exp not instanceof Function
    compiler.toCode(exp)
  else "(#{compiler.toCode(exp)})"

isStatement = (exp) ->
  exp_isStatement = exp?.isStatement
  if exp_isStatement then exp_isStatement.call(exp)
  else false

If::isStatement = () -> isStatement(@then_) or isStatement(@else_)
LabelStatement::isStatement = () -> true
While::isStatement = () -> true
For::isStatement = () -> true
ForIn::isStatement = () -> true
ForOf::isStatement = () -> true
Try::isStatement = () -> true
Begin::isStatement = () -> true
Return::isStatement = () -> true

vari = (klass, name) -> new klass(name)
il.uservar = (name) -> new UserVar(name)
il.internalvar = (name) -> v = new InternalVar( name)
il.internalconst = (name) -> v = new InternalVar( name); v.isConst = true; v
il.blockvar = (name) -> new BlockVar( name)
il.symbol = (name) -> new Symbol(name)

varattr = (klass, name) ->
  if not name? then return new klass(name)
  if name instanceof Var then name = name.name
  names = name.split('.');
  length = names.length
  result = new klass(names[0])
  for i in [1...length] then result = il.attr(result, il.symbol(names[i]))
  result
il.uservarattr = (name) -> varattr(UserVar, name)

il.assign = (left, exp) -> new Assign(left, exp)
il.paramassign = (left, exp) -> assign = new Assign(left, exp); assign.isParamAssign = true; assign
il.if_ = (test, then_, else_) -> new If(test, then_, else_)
il.deref = (exp) -> new Deref(exp)

il.begin = (exps...) ->
  length = exps.length
  if length is 0 then throw new Error "begin should have at least one exp"
  result = []
  for e in exps
    if e instanceof Begin then result = result.concat(e.exps)
    else result.push e
  if result.length is 1 then return result[0]
  else new Begin(result)
il.print = (exps...) -> new Print(exps)
il.return = (value) -> new Return(value)
il.throw = (value) -> new Throw(value)
il.new = (value) -> new New(value)
il.lamda = (params, body...) ->
  for p in params then p.isParameter = true
  new Lamda(params, il.begin(body...))
il.transparentlamda = (params, body...) ->
  for p in params then p.isParameter = true
  result = new Lamda(params, il.begin(body...))
  result.isTransparent = true
  result
il.optrec = (params, body...) ->
  for p in params then p.isParameter = true
  new OptimizableRecuisiveLamda(params, il.begin(body...))
il.tailrec = (params, body...) ->
  for p in params then p.isParameter = true
  new TailRecuisiveLamda(params, il.begin(body...))
il.userlamda = (params, body...) ->
  for p in params then p.isParameter = true
  new UserLamda(params, il.begin(body...))
il.transparentuserlamda = (params, body...) ->
  for p in params then p.isParameter = true
  result = new UserLamda(params, il.begin(body...))
  result.isTransparent = true
  result
il.blocklamda = (body...) -> new BlockLamda([], il.begin(body...))
il.clamda = (v, body...) -> v.isParameter = true; new Clamda(v, il.begin(body...))
il.recclamda = (v, body...) -> v.isParameter = true; new RecursiveClamda(v, il.begin(body...))
il.code = (string) -> new Code(string)
il.jsfun = (fun) -> new JSFun(fun)

binary = (symbol, func, effect=il.PURE) ->
  class Binary extends BinaryOperation
    symbol: symbol
    func: func
    _effect: effect
  (x, y) -> new Binary([x, y])
unary = (symbol, func, effect=il.PURE) ->
  class Unary extends UnaryOperation
    symbol: symbol
    func: func
    _effect: effect
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

il.listassign = (lefts..., exp) -> il.begin((il.assign(lefts[i], il.index(exp, i)) for i in [0...lefts.length])...)

il.not_ = unary("!", (x) -> !x)
il.neg = unary("-", (x) -> -x)
il.bitnot = unary("~", (x) -> ~x)
il.inc = il.effect(unary("++"), ((x) -> x+1), il.EFFECT)
il.dec = il.effect(unary("--"), ((x) -> x-1), il.EFFECT)

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

il.attr = vop('attr', ((compiler) -> args = @args; "#{expressionToCode(compiler, args[0])}.#{compiler.toCode(args[1])}"), il.PURE)
il.local = (vars...) -> new LocalDecl(vars)
il.nonlocal = (vars...) -> new NonlocalDecl(vars)
il.vardecl = vop('vardecl', (compiler)->args = @args; "var #{(compiler.toCode(e) for e in args).join(', ')}")
il.array = vop('array', (compiler)->args = @args; "[#{(compiler.toCode(e) for e in args).join(', ')}]")
il.uarray = vop('array', (compiler)->args = @args; "new UArray([#{(compiler.toCode(e) for e in args).join(', ')}])")
il.suffixinc = vop('suffixdec', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}++")
il.suffixdec = vop('suffixdec', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}--")
il.catches = il.uservarattr('solver.catches')
il.pushCatch = vop('pushCatch', (compiler)->args = @args; "solver.pushCatch(#{expressionToCode(compiler, args[0])}, #{expressionToCode(compiler, args[1])})")
il.popCatch = vop('popCatch', (compiler)->args = @args; "solver.popCatch(#{expressionToCode(compiler, args[0])})")
il.findCatch = vop('findCatch', ((compiler)->args = @args; "solver.findCatch(#{expressionToCode(compiler, args[0])})"), il.PURE)
il.fake = vop('fake', (compiler)->args = @args; "solver.fake(#{compiler.toCode(args[0])})").apply([])
il.restore = vop('restore', (compiler)->args = @args; "solver.restore(#{compiler.toCode(args[0])})")
il.getvalue = vop('getvalue', ((compiler)->args = @args; "solver.trail.getvalue(#{compiler.toCode(args[0])})"), il.PURE)
il.list = vop('list', ((compiler)->args = @args; "[#{(compiler.toCode(a) for a in args).join(', ')}]"), il.PURE)
il.length = vop('length', ((compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.length"), il.PURE)
il.index = vop('index', ((compiler)->args = @args; "#{expressionToCode(compiler, args[0])}[#{compiler.toCode(args[1])}]"), il.PURE)
il.slice = vop('slice', ((compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.slice(#{compiler.toCode(args[1])}, #{compiler.toCode(args[2])})"), il.PURE)
il.push = vop('push', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.push(#{compiler.toCode(args[1])})")
il.pop = vop('pop', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.pop()")
il.concat = vop('concat', ((compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.concat(#{compiler.toCode(args[1])})"), il.PURE)
il.instanceof = vop('instanceof', ((compiler)->args = @args; "#{expressionToCode(compiler, args[0])} instanceof #{expressionToCode(compiler, args[1])}"), il.PURE)
il.run = vop('run', (compiler)->args = @args; "solver.run(#{compiler.toCode(args[0])})")
il.evalexpr = vop('evalexpr', (compiler)->args = @args; "solve(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")
il.require = vop('require', (compiler)->args = @args; "require(#{compiler.toCode(args[0])})")

il.newLogicVar = vop('newLogicVar', ((compiler)->args = @args; "new Var(#{compiler.toCode(args[0])})"), il.PURE)
il.newDummyVar = vop('newDummyVar', ((compiler)->args = @args; "new DummyVar(#{compiler.toCode(args[0])})"), il.PURE)
il.unify = vop('unify', (compiler)->args = @args; "solver.trail.unify(#{compiler.toCode(args[0])}, #{compiler.toCode(args[1])})")
il.bind = vop('bind', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.bind(#{compiler.toCode(args[1])}, solver.trail)")

il.solver = il.uservar('solver')
il.undotrail = vop('undotrail', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.undo()")
il.failcont = il.uservarattr('solver.failcont')
il.setfailcont = (cont) -> il.assign(il.failcont, cont)
il.setcutcont = (cont) -> il.assign(il.cutcont, cont)
il.appendFailcont = vop('appendFailcont', (compiler)->args = @args; "solver.appendFailcont(#{compiler.toCode(args[0])})")
il.cutcont = il.uservarattr('solver.cutcont')
il.state = il.uservarattr('solver.state')
il.setstate = (state) -> il.assign(il.state, state)
il.trail = il.uservarattr('solver.trail')
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

il.label = (label, statement) -> new LabelStatement(label, statement)

il.while_ = (test, body...) -> new While(test, il.begin(body...))
il.dowhile = (body..., test) -> new DoWhile(test, il.begin(body...))
il.for_ = (init,test, step, body) -> new For(test, il.begin(body...))
il.forin = (vari, container, body...) -> new ForIn(vari, container, il.begin(body...))
il.forof = (vari, container, body...) -> new ForOf(vari, container, il.begin(body...))
il.try_ = (test, catches, final) -> new Try(test, catches, final)

il.break_ = (label) -> new Break(label)
il.continue_ = (label) -> new Continue(label)

il.idcont = do -> v = il.internalvar('v'); new IdCont(v, v)

il.excludes = ['evalexpr', 'failcont', 'run', 'getvalue', 'fake', 'findCatch', 'popCatch', 'pushCatch',
               'protect', 'suffixinc', 'suffixdec', 'dec', 'inc', 'unify', 'bind', 'undotrail',
               'newTrail', 'newLogicVar', 'char', 'followChars', 'notFollowChars', 'charWhen',
               'stringWhile', 'stringWhile0', 'number', 'literal', 'followLiteral', 'quoteString']

augmentOperators = {add: il.addassign, sub: il.subassign, mul: il.mulassign, div: il.divassign, mod: il.modassign,
'and_': il.andassign, 'or_': il.orassign, bitand: il.bitandassign, bitor:il.bitorassign, bitxor: il.bitxorassign,
lshift: il.lshiftassign, rshift: il.rshiftassign}