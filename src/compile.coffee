###
  规则（rule)：先对参数求值，再合一，然后求值规则体
  规则组：合并成单一规则
  rule Cons{x:1, y:Cons: ?x}

  macro
  宏：先合一，参数代入规则体（在规则体就地求值参数），求值替换后的规则体
  宏组：合并成单一宏

  合一: 类兼容，则继续字段合一


  最终都化成函数
###
I = require "f:/node-utils/src/importer"
[_, fs] = I.require_multiple "underscore fs"

I.use "f:/node-utils/src/set: set"
I.use "f:/node-utils/src/utils:   dict, assert, times_string, join, isinstance, toString"

il = require("../src/interlang")

prelude = ''

dao = exports
dao.toString = () -> 'dao'

dao.compileToJSFile = (exp, path, env) ->
  path = path or "f:\\daonode\\test\\compiled.js"
  code = dao.compileToJavascript exp, env
  fs.writeSync fs.openSync(path, 'w'), code

dao.compileToJavascript = (exp, env) ->
  compiler = new dao.Compiler()
  exp = dao.element(exp)
  exp = exp.alpha(env, compiler)
  exp = exp.cps(compiler, compiler.cont)
  exp.analyse(compiler)
  #  exp = exp.optimize(new dao.Environment(), compiler)
  #exp = exp.tail_recursive_convert()
  exp = il.begin(exp.javascriptize(env, compiler)[0])
  if (exp instanceof il.Begin)
    exp = exp.statements[0]
  exp = new il.Lamda([], exp)
  exp.body = exp.body.replace_return_with_pyyield()
  exp = new il.Call(exp, new il.ConstLocalVar('this'))
  exp.to_code(compiler)
#  return prelude + result

class dao.Exception
class dao.StopIteration extends dao.Exception
class dao.UncaughtThrow  extends dao.Exception
  constructor:  (@tag) ->
  toString = () -> @tag
class dao.SyntaxError  extends dao.Exception
class dao.Error extends dao.Exception
  constructor:  (@message) ->
  toString = () -> @message
class dao.CompileError extends dao.Exception
class dao.CompileTypeError  extends dao.CompileError
  constructor = (@exp) ->
  toString = () -> @exp.toString()
class dao.ArityError extends dao.CompileTypeError
class dao.VariableNotBound extends dao.CompileError
  constructor = (@vari) ->
  toString = () -> @vari.toString()
class dao.NotImplemented extends dao.CompileError
  constructor = (@message) ->
  toString = () -> @message
class dao.MultiAssignToConstError
  constructor:  (@const) ->
  toString: ( ) ->  @const.toString()

class dao.Environment
  '''environment for compilation, in alpha convert, block/exit/continue'''
  constructor: (@outer) -> @bindings = {}
  extend: () -> new Environment(@)
  get: (vari) -> if  @bindings[vari]?  else outer?.get(vari)
  set : (vari, value) ->  @bindings[vari] = value
  toString : () -> result = '';  env = @; ((result += JSON.stringify(env.bindings); env = env.outer) while env?);  result

class dao.Compiler
  constructor:  (env = new dao.Environment(), options) ->
    options = options or {}

    @newvar_map = {} #{'name':index}

    @cont = options.done or new il.Done(@new_var(new il.ConstLocalVar('v')))
    # for code generation
    @language = options.language  or "javascript"
    @indent_space = options.indent_space or "  "

    # for block/exit/continue
    @block_label_stack = []
    @exit_block_cont_map = {}
    @next_block_cont_map = {}
    @continue_block_cont_map = {}  # huh, next_block_cont_map or this?
    @protect_cont = @cont

    # for optimization
    @ref_count = {} # vari's reference count
    @called_count = {} # lambda's reference count
    @occur_count = {}
    @recursive_call_path = []

    @lamda_stack = []
    @recusive_variables_stack = [set()]

  new_var: (vari) ->
    suffix = @newvar_map[vari.name]
    if suffix?
      @newvar_map[vari.name] += 1
      new vari.constructor(vari.name+suffix)
    else
      @newvar_map[vari.name] = 1
      vari

  get_inner_block_label: () ->
    if @block_label_stack then @block_label_stack[-1][1]
    else throw new dao.BlockError("should not escape from top level outside of all block.")

  get_block_label: (old_label) ->
    for i in [@block_label_stack.length-1..0] by -1
      if old_label==@block_label_stack[i][0]
        return @block_label_stack[i][1]
    throw new dao.BlockError("Block #{old_label} is not found.")

  indent: (code, level=1) -> (times_string(@indent_space, level) + line for line in code.split '\n').join '\n'

MAX_EXTEND_CODE_SIZE = 10

import_names = []

register_fun = (name, fun) ->
  name = uniqueName(name, new_func_name_map)
  fun.func_name = name
  global[name] = fun
  import_names.append(name)
  fun

new_func_name_map = {}

uniqueName = (name, name2Suffix) ->
  suffix = name2Suffix[name]
  if suffix
    name2Suffix[name] += 1
    name+suffix
  else
    name2Suffix[name] = 1
    name

dao.element = (exp)->
  if (exp instanceof dao.Element) then exp
  else
    maker = dao.type_map[typeof(exp)]
    if maker then new maker(exp)
    else throw new dao.CompileTypeError(exp)

class dao.Element

class dao.Atom extends dao.Element
  constructor:  (@item) ->
class dao.Number extends dao.Atom
class dao.String extends dao.Atom
class dao.List extends dao.Atom
#class dao.Dict extends dao.Atom
class dao.Bool extends dao.Atom
class dao.Symbol extends dao.Atom

class dao.Var extends dao.Element
  constructor:  (@name) ->
class dao.LogicVar extends dao.Var
class dao.DummyVar extends dao.LogicVar

class dao.Const extends dao.Var
class dao.LamdaVar extends dao.Var
class dao.MacroVar extends dao.Var
class dao.ConstLamdaVar extends dao.LamdaVar
class dao.ConstMacroVar extends dao.MacroVar
class dao.RecursiveFunctionVar extends dao.ConstLamdaVar
class dao.RecursiveMacroVar extends dao.ConstMacroVar

class dao.Cons extends dao.Element
  constructor:  (@head, @tail) ->
class dao.Nil extends dao.Element

class dao.Command extends dao.Element
  constructor:  (@fun, @args) ->
class dao.Special extends dao.Command
  constructor:  (@name, @fun, @args) ->
class dao.BuiltinFunction extends dao.Command
  constructor:  (@name, @fun, @args) ->
class dao.Apply extends dao.Element
  constructor:  (@caller, @args) ->
class dao.Assign extends dao.Command
  constructor:  (@vari, @exp) ->
class dao.DirectInterlang extends dao.Element
  constructor:  (@body) ->
class dao.Lamda extends dao.Element
  constructor:  (@params, @body) ->
class dao.Macro extends dao.Element
  constructor:  (@params, @body) ->
class dao.Let extends dao.Element
  constructor:  (@bindings, @body) ->
class dao.Letrec extends dao.Element
  constructor:  (@bindings, @body) ->
class dao.Rules  extends dao.Lamda
  constructor:  (@rules) -> @arity = rules[0][0].length
class dao.MacroRules extends dao.Rules

# toString: be used as hash in {}, and used as eval to restore itself.
dao.Atom::toString = ( ) ->  "new dao.#{@constructor.name}(#{@item})"
dao.Var::toString = ( ) ->  "new dao.#{@constructor.name}(#{name})"
dao.Cons::toString = ( ) ->  "new dao.Cons(#{@head}, #{@tail})"
dao.Nil::toString = ( ) ->  'dao.nil'
dao.Apply::toString = ( ) ->  "new Dao.Apply(#{@caller}, [#{(x for x in @args).join ', '}])"
#dao.Special::toString = ( ) ->  "#{@name}(#{join(', ', (x for x in @args))})"
#dao.BuiltinFunction::toString = ( ) ->  "#{@fun.name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
dao.Assign::toString = ( ) ->  "dao.assign(#{@var1}, #{@exp})"
dao.Lamda::toString = () -> "dao.lamda([#{', '.join(x for x in @params)}], #{@body}"
dao.Macro::toString = () ->  "dao.macro((#{join(', ', [x for x in @params])}), #{@body})"
dao.Macro::toString = () -> "dao.let_(#{@bindings}, #{@body})"
dao.Letrec::toString = () -> "dao.letrec(#{@bindings}, #{@body})"
dao.Rules::toString = () -> "dao.rules(#{@rules})"
dao.MacroRules::toString = () -> "dao.macrorules(#{@rules})"

# ported from python's __eq__, not used until now.
dao.Atom::equal = (x, y) ->  x.constructor is y.constructor and x.item==y.item
dao.Number::equal = (x, y) -> Atom.equal(x, y) or (isinstance(y, int) and x.item==y)
dao.String::equal = (x, y) -> Atom.equal(x, y) or (isinstance(y, String) and x.item==y)
dao.List::equal = (x, y) -> Atom.equal(x, y) or (isinstance(y, Array) and x.item==y)
#dao.dict::equal = (x, y) -> Atom.equal(x, y) or (isinstance(y, Object) and x.item==y)
dao.Bool::equal = (x, y) -> Atom.equal(x, y) or (isinstance(y, Boolean) and x.item==y)
dao.Symbol::equal = (x, y) -> Atom.equal(x, y) or (isinstance(y, Symbol) and x.item==y)
dao.Var::equal = (x, y) ->  classeq(x, y) and x.name==y.name
dao.LogicVar::equal = (x, y) -> x.constructor is y.constructor and x.name==y.name # obviously unnecessary
dao.LogicVar::equal = (x, y) ->  classeq(x, y) and x.name==y.name
dao.Cons::equal = (other) -> @constructor is other.constructor and @head==other.head and @tail==other.tail
dao.Command::equal = (x, y) ->  classeq(x, y) and x.fun==y.fun and x.args==y.args
dao.Assign::equal = (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.exp==y.exp
dao.Lamda::equal = (x, y) -> classeq(x, y) and x.params==y.params and x.body==y.body
dao.Macro::equal = (x, y) -> classeq(x, y) and x.params==y.params and x.body==y.body

dao.Element::alpha = (env, compiler) -> @
dao.Var::alpha = (env, compiler) -> env.get(@)
dao.LogicVar::alpha = (env, compiler) -> @
dao.Cons::alpha = (env, compiler) ->
  new dao.Cons(@head.alpha(env, compiler),  @tail.alpha(env, compiler))

dao.Apply::alpha = (env, compiler) ->
  new @constructor(@caller.alpha(env, compiler),  (arg.alpha(env, compiler) for arg in @args))
dao.Special::alpha = (env, compiler) ->
  new @constructor(@name, @fun, (arg.alpha(env, compiler) for arg in @args))
dao.BuiltinFunction::alpha = (env, compiler) ->
  new @constructor(@name, @fun, (arg.alpha(env, compiler) for arg in @args))
dao.Assign::alpha = (env, compiler) ->
  vari = env.get(@vari)
  unless vari
    env.set(@vari, (vari = compiler.new_var(@vari)))
    if vari.isConst()
      vari.assigned = true
      return new dao.Assign(vari, @exp.alpha(env, compiler))
  if vari.isConst() and vari.assigned
    throw new dao.MultiAssignToConstError(vari)
  else new dao.Assign(vari, @exp.alpha(env, compiler))

# rule head, body
# first eval, then unify
dao.Rule::alpha = (env, compiler) ->

dao.Lamda::alpha = (env, compiler) ->
  new_env = env.extend()
  params = []
  for p in @params
    new_var = compiler.new_var(p)
    new_env.set p, new_var
    params.push(new_var)
  new @constructor(params, @body.alpha(new_env, compiler))

dao.Macro::alpha = (env, compiler) ->
  # macro means don't eval the args before eval the macro's body,
  # instead, eval in place the args in the body .
  new_env = env.extend()
  for p in @params
    new_env.bindings[p] = compiler.new_var(p)
  @params = new_env[p] for p in @params
  for vari, new_var in new_env.bindings.items()
    new_env.bindings[vari] = dao.eval_macro_args(new_var)
  @body = @body.alpha(new_env, compiler)
  @

dao.Macro::alpha = (env, compiler) ->
  new_env = env.extend()
  for vari, value in @bindings
    if isinstance(value, Rules)
      if not isinstance(vari, Const)
        new_var = compiler.new_var(LamdaVar(vari.name))
      else new_var = compiler.new_var(ConstLamdaVar(vari.name))
    else if isinstance(value, Lamda)
      if not isinstance(vari, Const)
        new_var = compiler.new_var(LamdaVar(vari.name))
      else new_var = compiler.new_var(ConstLamdaVar(vari.name))
    else if isinstance(value, MacroRules)
      if not isinstance(vari, Const)
        new_var = compiler.new_var(MacroVar(vari.name))
      else new_var = compiler.new_var(ConstMacroVar(vari.name))
    else new_var = compiler.new_var(vari)
    if isinstance(vari, Const)
      new_var.assigned = false
    env[vari ]  = new_var
  alphaed_body = @body.alpha(new_env, compiler)
  assign_bindings = Assign(new_env[vari], value.alpha(env, compiler)) for vari, value in @bindings
  return begin(assign_bindings+[alphaed_body]...)

dao.Letrec::alpha = (env, compiler) ->
  new_env = env.extend()
  for vari, value in @bindings
    if isinstance(value, Rules)
      new_var = compiler.new_var(RecursiveFunctionVar(vari.name))
    else if isinstance(value, Lamda)
      new_var = compiler.new_var(RecursiveFunctionVar(vari.name))
    else if isinstance(value, Macro)
      new_var = compiler.new_var(RecursiveMacroVar(vari.name))
    else if isinstance(value, MacroRules)
      new_var = compiler.new_var(RecursiveMacroVar(vari.name))
    else new_var = compiler.new_var(vari)
    if isinstance(new_var, Const)
      new_var.assigned = false
    new_env.bindings[vari] = new_var
  return begin((Assign(new_env[vari], value.alpha(new_env, compiler))  for vari, value in @bindings+[@body.alpha(new_env, compiler)])...)

# Rules connot have different arities in rule's head. MacroRules too.
dao.Rules::alpha = (env, compiler) ->
  rules = []
  for head, body in @rules
    [head, new_env] = alpha_rule_head(head, env, compiler)
    body = body.alpha(new_env, compiler)
    rules.push([head, body])
  new dao.Rules(rules)

dao.MacroRules::alpha = (env, compiler) ->
  result = []
  for head, body in @rules
    [head, new_env] = alpha_rule_head(head, env, compiler)
    for vari, new_var in new_env.bindings.items()
      new_env.bindings[vari] = eval_macro_args(new_var)
    body = body.alpha(new_env, compiler)
    result.push([head, body])
  return MacroRules(result)

dao.Element::subst = (bindings) -> @
dao.Var::subst = (bindings) -> if bindings.hasOwnProperty(@) then bindings[@] else @
dao.Apply::subst = (bindings) -> new @constructor(@caller.subst(bindings), (arg.subst(bindings) for arg in @args))
dao.Command::subst = (bindings) -> new @constructor(@fun,  (arg.subst(bindings) for arg in @args))
dao.Assign::subst = (bindings) -> Assign(@var1, @exp.subst(bindings))
dao.Macro::subst = (bindings) ->
  bindings = [vari.subst(bindings), value.subst(bindings)] for vari, value in @bindings
  body = @body.subst(bindings)
  new dao.Let(bindings, body)

dao.Atom::interlang = ( ) -> new il.Atom(@item)
dao.Number::interlang = ( ) -> new il.Integer(@item)
dao.String::interlang = ( ) -> new il.String(@item)
dao.List::interlang = ( ) -> new il.List(@item)
#dao.Dict::interlang = ( ) -> new il.Dict(@item)
dao.Bool::interlang = ( ) -> new il.Bool(@item)
dao.Symbol::interlang = ( ) -> new il.Symbol(@item)
dao.Var::interlang = ( ) ->  new il.Var(@name)
dao.LogicVar::interlang = ( ) ->  new il.LogicVar(@name)
dao.DummyVar::interlang = ( ) ->  new il.DummyVar(@name)
dao.Const::interlang = ( ) ->  new il.ConstLocalVar(@name)
dao.ConstLamdaVar::interlang = ( ) ->  new il.ConstLocalVar(@name)
dao.ConstMacroVar::interlang = ( ) ->  new il.ConstLocalVar(@name)
dao.RecursiveFunctionVar::interlang = ( ) ->  new il.RecursiveVar(@name)
dao.RecursiveMacroVar::interlang = ( ) ->  new il.RecursiveVar(@name)
dao.Cons::interlang = ( ) ->  new il.Cons(@head.interlang(), @tail.interlang())
dao.Nil::interlang = ( ) ->  il.nil
dao.BuiltinFunction::interlang = ( ) ->  @
dao.Lamda::interlang = () -> il.Lamda((x.interlang() for x in @params), @body.interlang())
dao.Macro::interlang = ()-> new il.Lamda((x.interlang() for x in @params), @body.interlang())

dao.Var::free_vars = ( ) ->  set([@])
dao.Special::free_vars = ( ) -> set.mergeAt( arg.free_vars() for arg in @args)
dao.BuiltinFunction::free_vars = ( ) -> set.mergeAt( arg.free_vars() for arg in @args)

dao.Var::callOn = (args...) -> new dao.Apply((element(arg) for arg in args))
dao.Macro::callOn = (args...) -> new daodao.Apply(element(arg) for arg in args)
dao.Lamda::callOn = (args...) -> new dao.Apply((element(arg) for arg in args))
dao.Rules::callOn = (args...) -> new dao.Apply((element(arg) for arg in args))
dao.MacroRules::callOn = (args...) -> new dao.Apply((element(arg) for arg in args))

dao.Atom::cps = (compiler, cont) ->  cont.callOn(@interlang())
dao.Var::cps = (compiler, cont) -> cont.callOn(@interlang())
dao.LogicVar::cps = (compiler, cont) -> cont.callOn(il.LogicVar(@name))
dao.DummyVar::cps = (compiler, cont) -> cont.callOn(il.Deref(il.DummyVar(@name)))
dao.Cons::cps = (compiler, cont) -> cont.callOn(@interlang())
dao.Apply::cps = (compiler, cont) ->  @caller.cps_call(compiler, cont, @args)
dao.BuiltinFunction::cps = (compiler, cont) ->
  #see The 90 minute Scheme to C compiler by Marc Feeley
  args = @args
  vars = (compiler.new_var(new il.ConstLocalVar('a'+i)) for i in [0...args])
  fun = cont.callOn(@fun.fun(vars...))
  for var1, arg in reversed(zip(vars, args))
    fun = arg.cps(compiler, new il.Clamda(var1, fun))
  fun

dao.Special::cps = (compiler, cont) -> @fun(compiler, cont, @args...)

dao.Assign::cps = (compiler, cont) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  @exp.cps(compiler, il.clamda(v, new il.Assign(@var1.interlang(), v), cont.callOn(v)))

dao.DirectInterlang::cps = (compiler, cont) ->  cont.callOn(@body)

dao.Lamda::cps = (compiler, cont)->
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  params = (x.interlang() for x in @params)
  if @has_cut() then body = wrap_cut(@body).cps(compiler, k)
  else  body = @body.cps(compiler, k)
  cont(il.Lamda([k]+params, body))

dao.Macro::cps = (compiler, cont) ->
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  params = (x.interlang() for x in @params)
  if @has_cut()
    body = wrap_cut(@body).cps(compiler, k)
  else body = @body.cps(compiler, k)
  cont(il.Lamda([k]+params, body))

dao.Rules::cps = (compiler, cont) ->
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  params = ([compiler.new_var(Const('arg')) for x in range(@arity)])
  clauses = []
  for head, body in @rules
    head_exps = begin((unify_head_item2(param, head_item) for param, head_item in zip(params, head)) ...)
    clauses.push(begin(head_exps, body))
  if @has_cut()
    body = wrap_cut(or_(clauses...)).cps(compiler, k)
  else body = or_(clauses...).cps(compiler, k)
  params = (param.interlang() for param in params)
  cont(il.Lamda([k]+params, body))

dao.MacroRules::cps = (compiler, cont) ->
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  params = compiler.new_var(new il.ConstLocalVar('arg')) for x in range(@arity)
  clauses = []
  for head, body in @rules
    head_exps = begin((unify_macro_head_item2(param, head_item)  for param, head_item in zip(params, head))...)
    clauses.push(begin(head_exps, body))
  if @has_cut()
    body = wrap_cut(or_(clauses...)).cps(compiler, k)
  else
    body = or_(clauses...).cps(compiler, k)
  cont(il.Lamda([k]+params, body))

# cps_convert_unify
dao.Var::cps_convert_unify = (x, y, compiler, cont) ->
  try y.cps_convert_unify
  catch e
    x = x.interlang()
    y = y.interlang()
    x1 = compiler.new_var(new il.ConstLocalVar(x.name))
    return il.begin(
                     new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
                     new il.If(il.IsLogicVar(x1),
                               il.begin(il.SetBinding(x1, y),
                                        il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                                        cont.callOn(il.TRUE)),
                               new il.If(il.Eq(x1, y), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))
  x = x.interlang()
  y = y.interlang()
  x1 = compiler.new_var(new il.ConstLocalVar(x.name))
  y1 = compiler.new_var(new il.ConstLocalVar(y.name))
  il.begin(
            new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
            new il.Assign(y1, new il.Deref(y)),
            new il.If(il.IsLogicVar(x1),
                      il.begin(il.SetBinding(x1, y1),
                               il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                               cont.callOn(il.TRUE)),
                      il.begin(
                                new il.If(il.IsLogicVar(y1),
                                          il.begin(il.SetBinding(y1, x1),
                                                   il.append_failcont.callOn(compiler, new il.DelBinding(y1)),
                                                   cont.callOn(il.TRUE)),
                                          new il.If(il.Eq(x1, y1), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))))

dao.Cons::cps_convert_unify = (x, y, compiler, cont) -> cps_convert_unify(x, y, compiler, cont)

dao.Cons::unify_rule_head = (other, env, subst) ->
  if @constructor isnt  other.constructor then return
  for _ in unify_rule_head(@head, other.head, env, subst)
    for _ in unify_rule_head(@tail, other.tail, env, subst)
      pyield true

dao.Cons::copy_rule_head = (env) ->
  head = copy_rule_head(@head, env)
  tail = copy_rule_head(@tail, env)
  if head==@head and tail==@tail then return @
  Cons(head, tail)

dao.Var::cps_call = (compiler, cont, args) ->
  # see The 90 minute Scheme to C compiler by Marc Feeley
  throw new dao.CompileTypeError(@)

  fun = compiler.new_var(new il.ConstLocalVar('fun'))
  vars = (compiler.new_var(new il.ConstLocalVar('a'+i)) for i in range(args.length))
  body = new il.Apply(fun, [cont]+vars)
  for var1, item in reversed(zip(vars, args))
    body = item.cps(compiler, il.clamda(var1, body))
    v = compiler.new_var(new il.ConstLocalVar('v'))
    macro_args1 = (il.ExpressionWithCode(arg, new il.Lamda([], arg.cps(compiler, il.clamda(v, v))))  for arg in args)
    macro_args2 = il.macro_args macro_args1
  @cps(compiler, il.clamda(fun,
                           new il.If(il.IsMacro(fun),
                                     new il.If(il.IsMacroRules(fun),
                                               new il.Apply(fun, [cont, macro_args2]),
                                               new il.Apply(fun, [cont]+macro_args1)),
                                     body)))

dao.Lamda::cps_call = (compiler, cont, args) ->
  # see The 90 minute Scheme to C compiler by Marc Feeley
  if @has_cut() then fun = wrap_cut(@body).cps(compiler, cont)
  else fun = @body.cps(compiler, cont)
  params = (x.interlang() for x in @params)
  for vari, arg in reversed(zip(params, args))
    fun = arg.cps(compiler, il.Clamda(vari, fun))
  fun

dao.Macro::cps_call = (compiler, cont, args) ->
  # see The 90 minute Scheme to C compiler by Marc Feeley
  if @has_cut()
    fun = wrap_cut(@body).cps(compiler, cont)
  else fun = @body.cps(compiler, cont)
  params = (x.interlang() for x in @params)
  for vari, arg in reversed(zip(params, args))
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    fun = direct_interlang(il.Lamda([k], arg.cps(compiler, k))).cps(compiler, il.Clamda(vari, fun))
  return fun

dao.Rules::cps_call = (compiler, cont, args) ->
  if args.length != @arity then throw new dao.ArityError
  clauses = []
  for head, body in @rules
    clauses.push(begin(unify_rule_head(args, head), body))
  if @has_cut()
    return wrap_cut(or_(clauses...)).cps(compiler, cont)
  else
    return or_(clauses...).cps(compiler, cont)

dao.LamdaVar::cps_call = (compiler, cont, args) ->
  #fun = compiler.new_var(new il.ConstLocalVar('fun'))
  fun = @interlang()
  vars = (compiler.new_var(new il.ConstLocalVar('a'+i))  for i in [0...args.length])
  body = new il.Apply(fun, [cont]+vars)
  for var1, item in reversed(zip(vars, args))
    body = item.cps(compiler, il.clamda(var1, body))
  v = compiler.new_var(new il.ConstLocalVar('v'))
  return @cps(compiler, il.clamda(fun,body))

dao.MacroVar::cps_call = (compiler, cont, args) ->
  fun = @interlang()
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  v = compiler.new_var(new il.ConstLocalVar('v'))
  #macro_args = (il.Lamda((), arg.cps(compiler, il.clamda(v, v)))
  #for arg in args)
  macro_args = (il.Lamda([k], arg.cps(compiler, k)) for arg in args)
  @cps(compiler, il.clamda(fun, new il.Apply(fun, [cont]+macro_args)))

dao.MacroRules::cps_call = (compiler, cont, args) ->
  if @arity!=args.length then throw
  clauses = []
  for head, body in @rules
    clauses.push(begin(unify_macro_head(compiler, cont, args, head), body))
  if @has_cut()
    return wrap_cut(or_(clauses...)).cps(compiler, cont)
  else or_(clauses...).cps(compiler, cont)

dao.BuiltinFunction::analyse = (compiler) ->

dao.BuiltinFunction::optimize = (env, compiler) -> @
# unquote to interlang level
dao.BuiltinFunction::javascriptize = (env, compiler) -> [@]

dao.Atom::to_code = (compiler) -> "#{@constructor.name}(#{@item})"
dao.Var::to_code = (compiler) -> "DaoVar('#{@name}')"
dao.LogicVar::to_code = (compiler) -> "dao.LogicVar('#{@name}')"
dao.DummyVar::to_code = (compiler) -> "DaoDummyVar('#{@name}')"
dao.Special::to_code = (compiler) -> "#{@name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
dao.BuiltinFunction::to_code = (compiler) -> "#{@fun.name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
dao.Assign::to_code = (compiler) ->  @.toString()

dao.LogicVar::deref = (bindings) ->
    # todo:
    # how to shorten the binding chain? need to change solver.fail_cont.
    # deref(solver) can help
    while 1
      next = bindings.getitem(@)
      if not isinstance(next, LogicVar) or next is @
        return next
      else next

cons = (head, tail) -> new Cons(element(head), element(tail))

dao.Cons::__iter__ = ( ) ->
    tail = @
    while 1
      pyield tail.head
      if tail.tail is nil then return
      else if isinstance(tail.tail, Cons)
        tail = tail.tail
      else
        pyield tail.tail
        return

dao.Cons::length = ( ) ->  (e for e in @).length
dao.Nil::length = ( ) ->  0

dao.Nil::__iter__ = ( ) -> if 0 then pyield

dao.nil = new dao.Nil()

dao.conslist = (elements...) ->
  result = nil
  for term in reversed(elements)
    result = new dao.Cons(element(term), result)
  result

dao.cons2tuple = (item) ->
  if not isinstance(item, Cons) and not isinstance(item, Array)
    item
  cons2tuple(x) for x in item

cps_convert_unify_two_var = (x, y, compiler, cont) ->
  x = x.interlang()
  y = y.interlang()
  x1 = compiler.new_var(new il.ConstLocalVar(x.name))
  y1 = compiler.new_var(new il.ConstLocalVar(y.name))
  il.begin(
            new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
            new il.Assign(y1, new il.Deref(y)),
            new il.If(il.IsLogicVar(x1),
                      il.begin(il.SetBinding(x1, y1),
                               il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                               cont.callOn(il.TRUE)),
                      il.begin(
                                il.If(il.IsLogicVar(y1),
                                      il.begin(il.SetBinding(y1, x1),
                                               il.append_failcont.callOn(compiler, new il.DelBinding(y1)),
                                               cont.callOn(il.TRUE)),
                                      new il.If(il.Unify(x1, y1), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))))

cps_convert_unify_one_var = (x, y, compiler, cont) ->
  x = x.interlang()
  y = y.interlang()
  x1 = compiler.new_var(new il.ConstLocalVar(x.name))
  il.begin(
                   new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
                   new il.If(il.IsLogicVar(x1),
                             il.begin(il.SetBinding(x1, y),
                                      il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                                      cont.callOn(il.TRUE)),
                             new il.If(new il.Unify(x1, y), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))

cps_convert_unify = (x, y, compiler, cont) ->
  if isinstance(x, Var)
    if isinstance(y , Var)
      cps_convert_unify_two_var(x, y, compiler, cont)
    else
      cps_convert_unify_one_var(x, y, compiler, cont)
  else
    if isinstance(y , Var)
      cps_convert_unify_two_var(y, x, compiler, cont)
    else
      if isinstance(x , Cons) and isinstance(y , Cons)
        v = compiler.new_var(new il.ConstLocalVar('v'))
        cps_convert_unify(x.head, y.head, compiler, il.clamda(v,
                              cps_convert_unify(x.tail, y.tail, compiler, cont)))
      else
        if x==y then cont.callOn(il.TRUE)
        else il.failcont.callOn(il.FALSE)

dao.Atom::quasiquote = (compiler, cont) -> cont.callOn(@interlang())

dao.Command::quasiquote = (compiler, cont) ->
    result = compiler.new_var(il.LocalVar('result'))
    vars = (compiler.new_var(new il.ConstLocalVar('a'+i)) for i in [0...@args])
    t = [new il.If(il.Isinstance(var1, new il.Klass('UnquoteSplice')),
                   new il.AddAssign(result, new il.Call(il.Symbol('list'), new il.Attr(var1, new il.Symbol('item')))),
                   new il.ListAppend(result, var1) ) for var1 in vars+[cont.callOn(il.Call(il.Klass(@constructor.name), new il.QuoteItem(@fun), new il.MakeTuple(result)))]]
    body = il.Assign(result, il.empty_list)+t
    fun = il.begin(body...)
    for var1, arg in reversed(zip(vars, @args))
      fun = arg.quasiquote(compiler, il.clamda(var1, fun))
    fun

dao.Lamda::make_new = (params, body) ->  new @constructor(params, body)
dao.Macro::make_new = (params, body) ->  new @constructor(params, body)

dao.Lamda::has_cut = () -> has_cut(@body)
dao.Macro::has_cut = () -> has_cut(@body)
dao.Rules::has_cut = () ->
  for head, body in @rules
    if has_cut(body) then return false
  return false

dao.MacroRules::has_cut = () ->
  for head, body in @rules
    if has_cut(body) then return false
  false

dao.number = (value) -> new dao.Number(value)
dao.string = (value) -> new dao.String(value)
dao.list = (value) -> new dao.List(value)
#dao.dict = (value) -> new dao.Dict(value)
dao.bool = (value) -> new dao.Bool(value)
dao.symbol = (value) -> new dao.Symbol(value)

dao.TRUE = new dao.Bool(true)
dao.FALSE = new dao.Bool(false)
dao.NULL = new dao.Atom(null)

dao.varialbe = (name) -> new dao.Var(name)
dao.special = (name, fun) -> (args...) -> new dao.Special(name, fun, dao.element x for x in args)
dao.assign = (var1, exp) -> new dao.Assign(var1, element(exp))
direct_interlang = (exps...) ->   new DirectInterlang(il.begin(exps...))
dao.lamda = (params, body...) -> new dao.Lamda(params, dao.begin((element(x) for x in body)...))
dao.macro = (params, body...) ->  new dao.Macro(params, begin((element(x) for x in body)...))

dao.let_ = (bindings, body...) ->
  bindings = [vari, element(value)] for vari, value in bindings
  new dao.Let(bindings, begin(body...))

dao.letrec = (bindings, body...) ->
  new dao.Letrec(([element(vari), element(value)] for vari, value in bindings), begin((element(exp) for exp in body))...)

dao.rules = (rules...)->
  result = []
  for rule in rules
    head = (element(x) for x in rule[0])
    body = begin((element(x) for x in rule[1...])...)
    result.push([head, body])
  return Rules(result)

macrorules = (rules...) ->
  result = []
  for rule in rules
    head = (element(x) for x in rule[0])
    body = begin((element(x) for x in rule[1...])...)
    result.push([head, body])
  MacroRules(result)

dao.begin = (exps...) ->
  exps = (dao.element(e) for e in exps)
  if exps.length==1 then  exps[0]
  else
    result = []
    for exp in exps
      if (exp instanceof dao.Special) and exp.command is dao.Begin
        result.concat(exp.args)
      else result.push(exp)
    dao.Begin.callOn(result...)

#@special
dao.expression_with_code = (compiler, cont, exp) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  cont.callOn(il.ExpressionWithCode(exp, new il.Lamda([], exp.cps(compiler, il.clamda(v, v)))))

#@special
dao.wrap_cut = (compiler, cont, exp) ->
  cut_cont = new il.ConstLocalVar('cut_cont')
  v = new il.ConstLocalVar('v')
  v1 = compiler.new_var(new il.ConstLocalVar('v'))
  v2 = compiler.new_var(new il.ConstLocalVar('v'))
  parse_state = compiler.new_var(new il.ConstLocalVar('parse_state'))
  bindings = compiler.new_var(il.LocalVar('bindings'))
  fc = compiler.new_var(new il.ConstLocalVar('old_failcont'))
  return il.begin(
                   il.Assign(cut_cont, il.cut_cont),
                   il.Assign(parse_state, il.parse_state),
                   il.Assign(bindings, il.Copy(il.bindings)),
                   il.Assign(fc, il.failcont),
                   il.SetCutCont(il.clamda(v2,
                                           il.Assign(il.parse_state, parse_state),
                                           il.SetBindings(bindings),
                                           fc(il.FALSE))),
                   il.SetFailCont(il.clamda(v1,
                                            il.SetFailCont(fc),
                                            il.Assign(il.cut_cont, cut_cont),
                                            fc(il.FALSE))),
                   exp.cps(compiler, il.clamda(v,
                                               il.Assign(il.cut_cont, cut_cont),
                                               cont(v))))
#@special
dao.eval_macro_args = (compiler, cont, exp)->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  il.Call(exp.interlang(), cont)

dao.quote = (compiler, cont, exp) -> cont(il.ExpressionWithCode(exp, il.Lamda([], exp.cps(compiler, il.equal_cont))))

eval_ = (compiler, cont, exp) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  exp.cps(compiler, il.clamda(v, cont(il.EvalExpressionWithCode(v))))

Begin_fun = (compiler, cont, exps...) -> cps_convert_exps(compiler, exps, cont)
dao.Begin = dao.special('begin', Begin_fun)

# utility functions
get_tuple_vars  = (exps) ->  set().mergeAt(x.vars() for x in exps)

alpha_rule_head = (head, env, compiler) ->
  new_env = env.extend()
  head2 = []
  for item in head
    head2.push(alpha_rule_head_item(item, new_env, compiler))
  [head2, new_env]

alpha_rule_head_item = (item, env, compiler) ->
  if isinstance(item, Var)
    if isinstance(item, Const)
      env.bindings[item] = result = compiler.new_var(Const(item.name))
    else
      env.bindings[item] = result = compiler.new_var(Var(item.name))
    return result
  else
    if isinstance(item, Cons)
      return Cons(alpha_rule_head_item(item.head, env, compiler),
                  alpha_rule_head_item(item.tail, env, compiler))
    else item

unify_rule_head = (args, head) ->
  il.begin((unify_head_item1(arg, head_item)  for [arg, head_item] in zip(args, head))...)

unify_head_item1 = (arg, head_item) ->
  # for direct call
  if isinstance(head_item, Var)
    if not isinstance(head_item, LogicVar)
      return Assign(head_item, arg)
    else throw new dao.CompileTypeError(head_item)
  else
    if isinstance(head_item, Cons)
      throw new dao.CompileTypeError(head_item)
    else return unify(arg, head_item)

do_unify_head_item2 = (arg, head_item, compiler, cont) ->
  if not isinstance(head_item, Var)
    # arg should be Var or il.ConsHead
    if isinstance(head_item, Cons)
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      return il.begin(il.Assign(arg1, il.Deref(arg)),
                      do_unify_head_item2(il.ConsHead(arg1), head_item.head, compiler,
                                          do_unify_head_item2(il.ConsTail(arg), head_item.tail, compiler, cont)))
    else
      head_item = head_item.interlang()
      arg = arg.interlang()
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      return il.begin(
                       il.Assign(arg1, il.Deref(arg)),
                       il.If(il.IsLogicVar(arg1),
                             il.begin(il.SetBinding(arg1, head_item),
                                      il.append_failcont(compiler, il.DelBinding(arg1)),
                                      cont(il.TRUE)),
                             il.If(il.Eq(arg1, head_item), cont(TRUE), il.failcont(TRUE))))
  else
    if not isinstance(head_item, LogicVar)
      arg = arg.interlang()
      return il.begin(
                       il.Assign(head_item.interlang(), arg),
                       cont(il.TRUE))
    else throw new dao.CompileTypeError

#@special
unify_head_item2 = (compiler, cont, arg, head_item) ->
  # for call with rules variable.
  arg = arg.interlang()
  if not isinstance(head_item, Var)
    # arg should be Var
    if isinstance(head_item, Cons)
      v = compiler.new_var(new il.ConstLocalVar('v'))
      return do_unify_head_item2(il.ConsHead(arg), head_item.head, compiler,
                                 il.clamda(v,
                                           do_unify_head_item2(il.ConsTail(arg), head_item.tail,
                                                               compiler, cont)))
    else
      head_item = head_item.interlang()
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      return il.begin(
                       il.Assign(arg1, il.Deref(arg)),
                       il.If(il.IsLogicVar(arg1),
                             il.begin(il.SetBinding(arg1, head_item),
                                      il.append_failcont(compiler, il.DelBinding(arg1)),
                                      cont(il.TRUE)),
                             il.If(il.Eq(arg1, head_item), cont(TRUE), il.failcont(TRUE))))
  else
    if not isinstance(head_item, LogicVar)
      return il.begin(
                       il.Assign(head_item.interlang(), arg),
                       cont(il.TRUE))
    else throw new dao.CompileTypeError

# for direct call
unify_macro_head = (compiler, cont, args, head) ->
  begin((unify_macro_head_item1(compiler, cont, arg, head_item)  for arg, head_item in zip(args, head))...)

# for direct call
unify_macro_head_item1 = (compiler, cont, arg, head_item) ->
  if isinstance(head_item, Var) and not isinstance(head_item, LogicVar)
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    return Assign(head_item, direct_interlang(il.Lamda([k], arg.cps(compiler, k))))
  else unify(arg, head_item)

#@special
unify_macro_head_item2 = (compiler, cont, arg, head_item) ->
  if isinstance(head_item, Var)
    if not isinstance(head_item, LogicVar)
      return il.begin(
                       il.Assign(head_item.interlang(), arg),
                       cont(il.TRUE))
    else
      v = compiler.new_var(new il.ConstLocalVar('v'))
      head_item = head_item.interlang()
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      head1 = compiler.new_var(new il.ConstLocalVar('head'))
      return il.begin(
                       il.Assign(arg1, il.Deref(arg)), #for LogicVar, could be optimized when generate code.
                       il.Assign(head1, il.Deref(head_item)),
                       il.If(il.IsLogicVar(arg1),
                             il.begin(il.SetBinding(arg1, head1),
                                      il.append_failcont(compiler, il.DelBinding(arg1)),
                                      cont(il.TRUE)),
                             il.begin(
                                       il.If(il.IsLogicVar(head1),
                                             il.begin(il.SetBinding(head1, arg1),
                                                      il.append_failcont(compiler, il.DelBinding(head1)),
                                                      cont(il.TRUE)),
                                             il.If(il.Eq(arg1, head1), cont(il.TRUE), il.failcont(il.FALSE))))))
  else
    arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
    return il.begin(
                     il.Assign(arg1, il.Deref(arg)),
                     il.If(il.IsLogicVar(arg1),
                           il.begin(il.SetBinding(arg1, head_item),
                                    il.append_failcont(compiler, il.DelBinding(arg1)),
                                    cont(il.TRUE)),
                           il.If(il.Eq(arg1, head_item), cont(TRUE), il.failcont(TRUE))))

dao.type_map = dict( "number", dao.Number,   "string",dao.String,     "boolean",dao.Bool,
                     "Array",dao.List,      "dict", dao.Dict,    typeof(->), dao.PyFunction
                     typeof(undefined) , dao.Atom
                   )