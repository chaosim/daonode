_ = require("underscore")
{Env, solve} = core = require("./core")

il = exports

exports.NotImplement = class NotImplement extends Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@name} >>> #{@exp} #{@message}"

toString = (o) -> o?.toString?() or o

expressionToCode = (compiler, exp) ->
  if exp instanceof Var or _.isString(exp) or _.isNumber(exp) or _.isArray(exp)\
     or exp instanceof VirtualOperation and (exp.name=='attr' or exp.name=='index')
    compiler.toCode(exp)
  else "(#{compiler.toCode(exp)})"

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
  isValue: () -> @isConst
class UserVar extends Var
class UserLocalVar extends UserVar
class UserNonlocalVar extends UserVar
class InternalVar extends Var
class InternalLocalVar extends InternalVar
class InternalNonlocalVar extends InternalVar
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

class ListAssign extends Assign
  constructor: (@lefts, @exp) -> @name = @toString()
  toString: () -> "#{toString(@lefts)} = #{toString(@exp)}"

class AugmentAssign extends Assign
  toString: () -> "#{toString(@left)} #{@operator} #{toString(@exp)}"

class Return extends Element
  constructor: (@value) -> super
  toString: () -> "return(#{toString(@value)})"
class New extends Return
  toString: () -> "new(#{toString(@value)})"
class Throw extends Return
  toString: () -> "throw(#{toString(@value)})"
class Begin extends Element
  constructor: (@exps) -> super
  toString: () -> "begin(#{(toString(e) for e in @exps).join(',')})"
class TopBegin extends Begin
  toString: () -> "topbegin(#{(toString(e) for e in @exps).join(',')})"
class Print extends Begin
  toString: () -> "print(#{(toString(e) for e in @exps).join(',')})"
class Lamda extends Element
  constructor: (@params, @body) -> super
  toString: () -> "(#{(toString(e) for e in @params).join(', ')} -> #{toString(@body)})"
  call: (args...) -> new Apply(@, args)
  isValue: () -> true
  apply: (args) -> new Apply(@, args)
class UserLamda extends Lamda
class Clamda extends Lamda
  constructor: (@v, @body) -> @name = @toString()
  toString: () -> "(#{toString(@v)} -> #{toString(@body)})"
#  call: (value) -> new CApply(@, value)
  call: (value) ->
    result = replace(@body, @v.toString(), value)
    if result.constructor is TopBegin then result.constructor = Begin
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

replace = (exp, param, value) ->
  exp_replace = exp?.replace
  if exp_replace then exp_replace.call(exp, param, value)
  else exp

Var::replace = (param, value) -> if @toString() is param then value else @
Assign::replace = (param, value) -> new @constructor(@left, replace(@exp, param, value))
ListAssign::replace = (param, value) -> new @constructor(@lefts, replace(@exp, param, value))
If::replace = (param, value) ->  new If(replace(@test, param, value), replace(@then_, param, value), replace(@else_, param, value))
Return::replace = (param, value) -> new @constructor(replace(@value, param, value))
Lamda::replace = (param, value) -> @ #param should not occur in Lamda
Clamda::replace = (param, value) -> @  #param should not occur in Clamda
IdCont::replace = (param, value) -> @
Apply::replace = (param, value) -> new Apply(replace(@caller, param, value), (replace(a, param, value) for a in @args))
VirtualOperation::replace = (param, value) -> new @constructor((replace(a, param, value) for a in @args))
Begin::replace = (param, value) -> new @constructor((replace(exp, param, value) for exp in @exps))
Deref::replace = (param, value) -> new Deref(value.replace(@exp, param))
Code::replace = (param, value) -> @
JSFun::replace = (param, value) ->  new JSFun(replace(@fun, param, value))

TASK_OPTIMIZE = 0;
TASK_FUNC = 1

exports.optimize = (exp, env, compiler) ->
  result = null
  compiler.tasks = tasks = []
  tasks.push(null, [TASK_OPTIMIZE, exp, env])
  while 1
    task = tasks.pop()
    if not task then break
    switch task[0]
      when TASK_OPTIMIZE then result = optimize(task[1], task[2], compiler)
      when TASK_FUNC then result = task[1](result)
  result

optimize = (exp, env, compiler) ->
  exp_optimize = exp?.optimize
  if exp_optimize then exp_optimize.call(exp,  env, compiler)
  else exp

appendTasks = (compiler, tasks) ->
  compilerTasks = compiler.tasks
  for i in [tasks.length- 1..0]
    compilerTasks.push(tasks[i])

Var::optimize = (env, compiler) ->
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

Assign::optimize = (env, compiler) ->
  left = @left
  if left instanceof VirtualOperation
    left = new left.constructor(optimize(a, env, compiler) for a in left.args)
  else
    if left.isConst
      if left.haveAssigned then throw Error(@, "should not assign to const more than once.")
      else left.haveAssigned = true
    if left instanceof UserLocalVar
      locals = env.userlamda?.locals
      if locals
        if locals[left]? then locals[left]++
        else locals[left] = 1
    else if left instanceof UserNonlocalVar
      env.userlamda?.nonlocals[left] = left
    else if left instanceof InternalLocalVar then  env.lamda?.locals[left] = left
    else if left instanceof InternalNonlocalVar then  env.lamda?.nonlocals[left] = left
  tasks = []
  tasks.push([TASK_OPTIMIZE, @exp, env])
  tasks.push([TASK_FUNC, ((exp) =>
    assign = new @constructor(left, exp)
    outerEnv = env.outer
    if outerEnv
      envExp = outerEnv.lookup(left)
      if envExp instanceof Assign then envExp._removed = false
    if isValue(exp)
      if exp instanceof Lamda and left.isRecursive
        env.bindings[left] = exp
        assign._removed = false
      else if not isAtomic(exp)
        env.bindings[left] = exp
        assign._removed = false
      else if left instanceof VirtualOperation
        assign._removed = false
      else
        env.bindings[left] = assign
    else
      env.bindings[left] = left
      assign._removed = false
    assign)])
  appendTasks(compiler, tasks)

LocalDecl::optimize = (env, compiler) ->
  for vari in @vars
    if vari instanceof UserVar then env.userlamda.locals[vari] = vari
    else env.lamda.locals[vari] = vari
  null

NonlocalDecl = (env, compiler) ->
  for vari in @vars
    if vari instanceof UserVar then env.userlamda.nonlocals[vari] = vari
    else env.lamda.nonlocals[vari] = vari
  null

If::optimize = (env, compiler) ->
  tasks = []
  tasks.push([TASK_OPTIMIZE, @test, env])
  tasks.push([TASK_FUNC, ((test) =>
    test_bool = boolize(test)
    if test_bool is true
      tasks = []
      tasks.push([TASK_OPTIMIZE, @then_, env])
      tasks.push([TASK_FUNC, ((then_) ->
        if then_ instanceof If and then_.test is test # (if a (if a b c) d)
          then_ = then_.then_
        then_)])
      appendTasks(compiler, tasks)
    else if test_bool is false
      tasks = []
      tasks.push([TASK_OPTIMIZE, @else_, env])
      tasks.push([TASK_FUNC, ((else_) ->
        if else_ instanceof If and else_.test is test # (if a b (if a c d))
          else_ = else_.else_
        else_)])
      appendTasks(compiler, tasks)
    else
      tasks = []
      tasks.push([TASK_OPTIMIZE, @then_, env])
      tasks.push([TASK_FUNC, ((then_) ->
          tasks = []
          tasks.push([TASK_OPTIMIZE, @else_, env])
          tasks.push([TASK_FUNC, ((else_) ->
            if then_ instanceof If and then_.test is test # (if a (if a b c) d)
              then_ = then_.then_
            if else_ instanceof If and else_.test is test # (if a b (if a c d))
              else_ = else_.else_
            new If(test, then_, else_))])
          appendTasks(compiler, tasks)
        )])
      appendTasks(compiler, tasks))
  ])
  appendTasks(compiler, tasks)

Throw::optimize = (env, compiler) ->
  tasks = []
  tasks.push([TASK_OPTIMIZE, @value, env])
  tasks.push([TASK_FUNC, ((value) -> new Throw(value))])
  appendTasks(compiler, tasks)
New::optimize = (env, compiler) ->
  tasks = []
  tasks.push([TASK_OPTIMIZE, @value, env])
  tasks.push([TASK_FUNC, ((value) -> new New(value))])
  appendTasks(compiler, tasks)
IdCont::optimize = (env, compiler) -> @

Clamda::optimize = (env, compiler) ->
  if @_optimized then return @
  tasks = []
  #  envBindings = env.bindings
  #  for k,v of envBindings
  #    if hasOwnProperty.call(envBindings, k) and v instanceof Assign
  #      v._removed = false
  bindings = {}; bindings[@v] = @v
  @locals = {}; @nonlocals = {}; @vars = {}; @childrenLamda = []
  env = env.extendBindings(bindings, @)
  tasks.push([TASK_OPTIMIZE, @body, env])
  tasks.push([TASK_FUNC, ((body) =>
    @body = jsify(body, compiler, env)
    @_jsified = true
    #  vars = @allVars()
    @_optimized = true
    @)])
  appendTasks(compiler, tasks)

UserLamda::optimize = (env, compiler) ->
  tasks = []
  if @_optimized then return @
  #  envBindings = env.bindings
  #  for k,v of envBindings
  #    if hasOwnProperty.call(envBindings, k) and v instanceof Assign
  #      v._removed = false
  bindings = {}
  for p in @params then bindings[p] = p
  @locals = {}; @nonlocals = {}; @vars = {}; @childrenLamda = []
  env = env.extendBindings(bindings,@, @)
  tasks.push([TASK_OPTIMIZE, @body, env])
  tasks.push([TASK_FUNC, ((body) =>
    @body = jsify(body, compiler, env)
    @_jsified = true
    #  vars = @allVars()
    @_optimized = true
    @)])
  appendTasks(compiler, tasks)

Lamda::optimize = (env, compiler) ->
  tasks = []
  if @_optimized then return @
  env.lamda.childrenLamda.push(@)
#  envBindings = env.bindings
#  for k,v of envBindings
#    if hasOwnProperty.call(envBindings, k) and v instanceof Assign
#      if vars[k] then v._removed = false
  bindings = {}
  for p in @params then bindings[p] = p
  @locals = {}; @nonlocals = {}; @vars = {}; @childrenLamda = []
  env = env.extendBindings(bindings, @)
  tasks.push([TASK_OPTIMIZE, @body, env])
  tasks.push([TASK_FUNC, ((body) =>
    @body = jsify(body, compiler, env)
    @_jsified = true
    #  vars = @allVars()
    @_optimized = true
    @)])
  appendTasks(compiler, tasks)

Apply::optimize = (env, compiler) ->
  tasks = []
  tasks.push([TASK_OPTIMIZE, @caller, env])
  tasks.push([TASK_FUNC, ((caller) =>
    tasks = []
    optimizeApply = caller.optimizeApply
    if optimizeApply then optimizeApply.call(caller, @args, env, compiler)
    else
      args = []
      for a in @args
        tasks.push([TASK_OPTIMIZE, a, env])
        tasks.push([TASK_FUNC, ((arg) -> args.push(arg); args)])
      tasks.push([TASK_FUNC, (args) -> new Apply(caller, args)])
      appendTasks(compiler, tasks)
    )])
  appendTasks(compiler, tasks)

VirtualOperation::optimize = (env, compiler) ->
  tasks = []
  args = []
  for a in @args
    tasks.push([TASK_OPTIMIZE, a, env])
    tasks.push([TASK_FUNC, ((arg) -> args.push(arg); args)])
  tasks.push([TASK_FUNC, ((args) =>
    _isValue = true
    for a in args
      if not isValue(a) then _isValue = false; break
    if _isValue and @func then @func.apply(null, args)
    else new @constructor(args))])
  appendTasks(compiler, tasks)

Begin::optimize = (env, compiler) ->
  tasks = []
  result = []
  waitPop = false
  thisExps = @exps
  tasks.push([TASK_OPTIMIZE, thisExps.shift(), env])
  task = [TASK_FUNC, ((e) ->
    if not isDeclaration(e)
      if waitPop then result.pop()
      if e instanceof Begin
        exps = e.exps
        result = result.concat(exps)
        waitPop = sideEffect(result[result.length-1]) is il.PURE
      else
        result.push e
        waitPop = sideEffect(e) is il.PURE
    if thisExps.length
      tasks = []
      tasks.push([TASK_OPTIMIZE, thisExps.shift(), env])
      tasks.push(task)
      appendTasks(compiler, tasks)
  )]
  tasks.push(task)
  tasks.push([TASK_FUNC, ((x) =>
    if result.length>1 then  new @constructor(result)
    else result[0])])
  appendTasks(compiler, tasks)

Deref::optimize = (env, compiler) ->
  exp = @exp
  if _.isString(exp) then exp
  else if _.isNumber(exp) then exp
  else
    tasks = []
    tasks.push([TASK_OPTIMIZE, @value, env])
    tasks.push([TASK_FUNC, ((value) -> new Deref(value))])
    appendTasks(compiler, tasks)

Code::optimize = (env, compiler) -> @

JSFun::optimize = (env, compiler) ->
  tasks = []
  tasks.push([TASK_OPTIMIZE, @fun, env])
  tasks.push([TASK_FUNC, ((value) -> new JSFun(value))])
  appendTasks(compiler, tasks)

Lamda::optimizeApply = (args, env, compiler) ->
  tasks = []
  exps = (il.assign(p, args[i]) for p, i in @params)
  exps.push @body
  tasks.push([TASK_OPTIMIZE, il.topbegin(exps...), env])
  tasks.push([TASK_FUNC, ((body) ->
    if not isStatement(body) then body
    else new Apply(new Lamda([], body), [])
  )])
  appendTasks(compiler, tasks)

Clamda::optimizeApply = (args, env, compiler) ->
  tasks = compiler.tasks
  tasks.push([TASK_OPTIMIZE, il.begin(il.assign(@v, args[0]), @body), env])

RecursiveClamda::optimizeApply = (args, env, compiler) ->
  tasks = compiler.tasks
  tasks.push([TASK_OPTIMIZE, il.begin(il.assign(@v, args[0]), @body), env])

IdCont::optimizeApply = (args, env, compiler) -> optimize(args[0], env, compiler)

JSFun::optimizeApply = (args, env, compiler) ->
  tasks = []
  optimizedArgs = []
  for a in args
    tasks.push([TASK_OPTIMIZE, a, env])
    tasks.push([TASK_FUNC, ((arg) -> optimizedArgs.push(arg); optimizedArgs)])
  f = @fun
  tasks.push([TASK_FUNC, ((args) ->
    t = typeof f
    if t is 'function' then new Apply(f, args)
    else if t is 'string' then new Apply(il.fun(f), args)
    else f.apply(args).optimize(env, compiler))])
  appendTasks(compiler, tasks)

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
Apply::boolize = () ->
  caller = @caller
  if caller instanceof Lamda or caller instanceof Clamda then return boolize(caller.body)
  if caller instanceof Var then return undefined
  for a in @args then if boolize(a) is undefined then return undefined
  !!(caller.func?.apply(null, @args)) or undefined
CApply::boolize = () -> boolize(@caller.body)

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
Return::sideEffect = () -> sideEffect(@value)
Throw::sideEffect = () -> il.IO
New::sideEffect = () -> sideEffect(@value)
If::sideEffect = () -> expsEffect [@test, @then_, @else_]
Begin::sideEffect = () -> expsEffect(@exps)
Lamda::sideEffect = () ->  il.PURE
JSFun::sideEffect = () ->  il.PURE
Fun::sideEffect = () ->  il.PURE
Apply::sideEffect = () ->  Math.max(applySideEffect(@caller), expsEffect(@args))
VirtualOperation::sideEffect = () ->  Math.max(@_effect, expsEffect(@args))
CApply::sideEffect = () -> Math.max(applySideEffect(@caller), sideEffect(@args[0]))

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

setJsified = (exp) -> exp?._jsified = true; exp
isJsified = (exp) -> exp?._jsified or false

jsify = (exp, compiler, env) ->
  if isJsified(exp) then return exp
  exp_jsify = exp?.jsify
  if exp_jsify then exp_jsify.call(exp, compiler, env)
  else exp

Assign::jsify = (compiler, env) -> @exp = jsify(@exp, compiler, env); @
Return::jsify = (compiler, env) -> new @constructor(jsify(@value, compiler, env))
If::jsify = (compiler, env) ->
  new If(jsify(@test, compiler, env), jsify(@then_, compiler, env), jsify(@else_, compiler, env))

Begin::jsify = (compiler, env) ->
  exps = @exps
  length = exps.length
  if length is 0 or length is 1
    throw new  Error "begin should have at least one exp"
  result = []
  waitPop = false
  for e in exps
    if e instanceof Assign and e.removed() then continue
    if waitPop then result.pop()
    e = jsify(e, compiler, env)
    if e instanceof Begin
      result = result.concat e.exps
      waitPop = sideEffect(result[result.length-1]) is il.PURE
    else if e instanceof New
      result.push e
      waitPop = sideEffect(e) is il.PURE
    else if e instanceof Throw then result.push e; break
    else if e instanceof Return then throw new Error(e)
    else result.push(e); waitPop = sideEffect(e) is il.PURE
  if result.length==1 then result[0]
  else new @constructor(result)

Lamda::jsify = (compiler, env) ->
  locals = []
  nonlocals = @nonlocals
  locals1 = @locals
  for k of locals1
    if not hasOwnProperty.call(nonlocals, k) and k not in @params then locals.push(il.symbol(k))
  body = jsify(@body, compiler, env)
  if locals.length>0 then new Lamda(@params, il.topbegin(il.vardecl(locals...), body))
  else new Lamda(@params, body)

Clamda::jsify = (compiler, env) ->
  locals = []
  nonlocals = @nonlocals
  locals1 = @locals
  for k of locals1
    if not hasOwnProperty.call(nonlocals, k) and k.name isnt @v.name then locals.push(il.symbol(k))
  body = jsify(@body, compiler, env)
  if locals.length>0 then il.clamda(@v,il.vardecl(locals...), body)
  else  il.clamda(@v, body)

Apply::jsify = (compiler, env) ->
  caller = @caller
  if caller instanceof Lamda and caller.params.length is 0
    body = jsify(caller.body, compiler, env)
    if not isStatement(body) then body
    else new Apply(new caller.constructor([], body), [])
  else
    new @constructor(jsify(@caller, compiler, env), (jsify(a, compiler, env) for a in @args))


VirtualOperation::jsify = (compiler, env) -> new @constructor(jsify(a, compiler, env) for a in @args)

il.insertReturn = insertReturn = (exp) ->
  exp_insertReturn = exp?.insertReturn
  if exp_insertReturn then exp_insertReturn.call(exp)
  else new Return(exp)

Assign::insertReturn = () -> il.begin(@, il.return(@left))
Return::insertReturn = () -> @
New::insertReturn = () -> new Return(@)
If::insertReturn = () ->
  if @isStatement() then new If(@test, insertReturn(@then_), insertReturn(@else_))
  else new Return(@)
Begin::insertReturn = () ->
  exps = @exps
  length = exps.length
  last = insertReturn(exps[length-1])
  begin(@constructor, [exps[0...length-1]..., last]...)

Lamda::toCode = (compiler) ->
  compiler.parent = @
  body = insertReturn(@body)
  "function(#{(a.toString() for a in @params).join(', ')}){#{compiler.toCode(body)}}"
Clamda::toCode = (compiler) ->
  compiler.parent = @
  body = insertReturn(@body)
  "function(#{@v.toString()}){#{compiler.toCode(body)}}"
Fun::toCode = (compiler) -> @func.toString()
Return::toCode = (compiler) -> "return #{compiler.toCode(@value)};"
Throw::toCode = (compiler) -> "throw #{compiler.toCode(@value)};"
New::toCode = (compiler) -> "new #{compiler.toCode(@value)}"
Var::toCode = (compiler) -> @toString()
NonlocalDecl::toCode = (compiler) -> ''
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
  "#{expressionToCode(compiler, @caller)}(#{(compiler.toCode(arg) for arg in @args).join(', ')})"
CApply::toCode = (compiler) -> "#{expressionToCode(compiler, @caller)}(#{compiler.toCode(@args[0])})"
Begin::toCode = (compiler) -> compiler.parent = @; "{#{(compiler.toCode(exp) for exp in @exps).join('; ')}}"
TopBegin::toCode = (compiler) -> compiler.parent = @; "#{(compiler.toCode(exp) for exp in @exps).join('; ')}"
Print::toCode = (compiler) ->  "console.log(#{(compiler.toCode(exp) for exp in @exps).join(', ')})"
Deref::toCode = (compiler) ->  "solver.trail.deref(#{compiler.toCode(@exp)})"
Code::toCode = (compiler) ->  @string
JSFun::toCode = (compiler) ->  if _.isString(@fun) then @fun  else compiler.toCode(@fun)

isStatement = (exp) ->
  exp_isStatement = exp?.isStatement
  if exp_isStatement then exp_isStatement.call(exp)
  else false

If::isStatement = () -> isStatement(@then_) or isStatement(@else_)
Begin::isStatement = () -> true
Return::isStatement = () -> true
New::isStatement = () -> false
Assign::isStatement = () -> true

vari = (klass, name) -> new klass(name)
il.userlocal = (name) -> new UserLocalVar(name)
il.usernonlocal = (name) -> new UserNonlocalVar(name)
il.internallocal = (name) -> new InternalLocalVar( name)
il.internalnonlocal = (name) -> new InternalNonlocalVar(name)
il.symbol = (name) -> new Symbol(name)

varattr = (klass, name) ->
  if not name? then return new klass(name)
  if name instanceof Var then name = name.name
  names = name.split('.');
  length = names.length
  result = new klass(names[0])
  for i in [1...length] then result = il.attr(result, il.symbol(names[i]))
  result
il.usernonlocalattr = (name) -> varattr(UserNonlocalVar, name)

il.assign = (left, exp) -> new Assign(left, exp)
il.userlocalassign = (left, exp) ->
  if left instanceof Var then left = left.name
  new Assign(il.userlocal(left), exp)
il.usernonlocalassign = (left, exp) ->
  if left instanceof Var then left = left.name
  new Assign(il.usernonlocal(left), exp)
il.internallocalassign = (left, exp) ->
  if left instanceof Var then left = left.name
  new Assign(il.internallocal(left), exp)
il.internalnonlocalassign = (left, exp) ->
  if left instanceof Var then left = left.name
  new Assign(il.internalnonlocal(left), exp)
il.if_ = (test, then_, else_) -> new If(test, then_, else_)
il.deref = (exp) -> new Deref(exp)

begin = (klass, exps...) ->
  length = exps.length
  if length is 0 then throw new Error "begin should have at least one exp"
  result = []
  for e in exps
    if e instanceof Begin then result = result.concat(e.exps)
    else result.push e
  if result.length is 1 then return result[0]
  else new klass(result)
il.begin = (exps...) -> begin(Begin, exps...)
il.topbegin = (exps...) -> begin(TopBegin, exps...)
il.print = (exps...) -> new Print(exps)
il.return = (value) -> new Return(value)
il.throw = (value) -> new Throw(value)
il.new = (value) -> new New(value)
il.lamda = (params, body...) -> new Lamda(params, il.topbegin(body...))
il.userlamda = (params, body...) -> new UserLamda(params, il.topbegin(body...))
il.clamda = (v, body...) -> new Clamda(v, il.topbegin(body...))
il.recclamda = (v, body...) -> new RecursiveClamda(v, il.topbegin(body...))
il.clamdabody = (v, body) -> new ClamdaBody(v, body)
il.code = (string) -> new Code(string)
il.jsfun = (fun) -> new JSFun(fun)

binary = (symbol, func, effect=il.PURE) ->
  class Binary extends BinaryOperation
    symbol: symbol
    toCode: (compiler) -> args = @args; "#{expressionToCode(compiler, args[0])} #{symbol} #{expressionToCode(compiler, args[1])}"
    func: func
    _effect: effect
  (x, y) -> new Binary([x, y])
unary = (symbol, func, effect=il.PURE) ->
  class Unary extends UnaryOperation
    symbol: symbol
    func: func
    _effect: effect
    toCode: (compiler) -> "#{symbol}#{expressionToCode(compiler, @args[0])}"
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
il.nonlocal = (vars) -> new NonlocalDecl(vars)
il.local = (vars...) -> new LocalDecl(vars)
il.vardecl = vop('vardecl', (compiler)->args = @args; "var #{(compiler.toCode(e) for e in args).join(', ')}")
il.array = vop('array', (compiler)->args = @args; "[#{(compiler.toCode(e) for e in args).join(', ')}]")
il.suffixinc = vop('suffixdec', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}++")
il.suffixdec = vop('suffixdec', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}--")
il.catches = il.usernonlocalattr('solver.catches')
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

il.solver = il.usernonlocal('solver')
il.undotrail = vop('undotrail', (compiler)->args = @args; "#{expressionToCode(compiler, args[0])}.undo()")
il.failcont = il.usernonlocalattr('solver.failcont')
il.setfailcont = (cont) -> il.assign(il.failcont, cont)
il.setcutcont = (cont) -> il.assign(il.cutcont, cont)
il.appendFailcont = vop('appendFailcont', (compiler)->args = @args; "solver.appendFailcont(#{compiler.toCode(args[0])})")
il.cutcont = il.usernonlocalattr('solver.cutcont')
il.state = il.usernonlocalattr('solver.state')
il.setstate = (state) -> il.assign(il.state, state)
il.trail = il.usernonlocalattr('solver.trail')
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

il.idcont = do -> v = il.internallocal('v'); new IdCont(v, v)

il.excludes = ['evalexpr', 'failcont', 'run', 'getvalue', 'fake', 'findCatch', 'popCatch', 'pushCatch',
               'protect', 'suffixinc', 'suffixdec', 'dec', 'inc', 'unify', 'bind', 'undotrail',
               'newTrail', 'newLogicVar', 'char', 'followChars', 'notFollowChars', 'charWhen',
               'stringWhile', 'stringWhile0', 'number', 'literal', 'followLiteral', 'quoteString']

augmentOperators = {add: il.addassign, sub: il.subassign, mul: il.mulassign, div: il.divassign, mod: il.modassign,
'and_': il.andassign, 'or_': il.orassign, bitand: il.bitandassign, bitor:il.bitorassign, bitxor: il.bitxorassign,
lshift: il.lshiftassign, rshift: il.rshiftassign
}